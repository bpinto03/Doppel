extends Node

## Plays sound effects and music on their own buses, following the sound, music and volume settings.

signal effect_played(effect: SoundEffect)

const MASTER_BUS: StringName = &"Master"
const SFX_BUS: StringName = &"SFX"
const MUSIC_BUS: StringName = &"Music"
const CONFIG: AudioConfig = preload("res://data/audio_config.tres")

var _music_player := AudioStreamPlayer.new()
var _effect_players: Array[AudioStreamPlayer] = []
var _next_taken_player_index: int
var _variation_rng := RandomNumberGenerator.new()


func _ready() -> void:
	_music_player.bus = MUSIC_BUS
	add_child(_music_player)
	for index: int in CONFIG.player_pool_size:
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		_effect_players.append(player)
	Settings.changed.connect(apply_settings)
	apply_settings()


## Returns the player used, or null when the effect has no sound yet: a missing sound is never an error.
func play_effect(effect: SoundEffect, pitch_scale: float = 1.0) -> AudioStreamPlayer:
	if effect == null or effect.stream == null:
		return null
	var player: AudioStreamPlayer = _take_effect_player()
	player.stream = effect.stream
	player.pitch_scale = pitch_scale * _vary(effect.pitch_variation_percent)
	player.volume_db = effect.volume_offset_db + linear_to_db(_vary(effect.volume_variation_percent))
	player.play()
	effect_played.emit(effect)
	return player


func get_effect_player_count() -> int:
	return _effect_players.size()


func play_music(stream: AudioStream) -> void:
	_music_player.stream = stream
	_apply_music_setting()


## Called at startup and on every settings change, so the saved state always applies.
func apply_settings() -> void:
	_apply_bus(MASTER_BUS, true)
	_apply_bus(SFX_BUS, Settings.is_sound_enabled)
	_apply_bus(MUSIC_BUS, Settings.is_music_enabled)
	_apply_music_setting()


## A volume of zero mutes the bus, since its decibel value would be minus infinity.
func _apply_bus(bus_name: StringName, is_enabled: bool) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	var volume: float = Settings.get_bus_volume(bus_name)
	AudioServer.set_bus_mute(bus_index, not is_enabled or volume <= 0.0)
	if volume > 0.0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume))


## A free player if there is one, else the players are taken in turn, so the oldest sound is cut first.
func _take_effect_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _effect_players:
		if not player.playing:
			return player
	var player: AudioStreamPlayer = _effect_players[_next_taken_player_index]
	_next_taken_player_index = (_next_taken_player_index + 1) % _effect_players.size()
	return player


## A factor around 1, spread by the given percentage either way.
func _vary(variation_percent: float) -> float:
	var spread: float = variation_percent / 100.0
	return 1.0 + _variation_rng.randf_range(-spread, spread)


func _apply_music_setting() -> void:
	var should_play: bool = Settings.is_music_enabled and _music_player.stream != null
	if should_play and not _music_player.playing:
		_music_player.play()
	elif not should_play:
		_music_player.stop()
