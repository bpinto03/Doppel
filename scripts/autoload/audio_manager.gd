extends Node

## Plays sound effects and music on their own buses, following the sound, music and volume settings.

signal effect_played(effect: SoundEffect)

const MASTER_BUS: StringName = &"Master"
const SFX_BUS: StringName = &"SFX"
const MUSIC_BUS: StringName = &"Music"
const CONFIG: AudioConfig = preload("res://data/audio_config.tres")
## Low enough to be inaudible: fades start and end here.
const SILENT_DB: float = -80.0

var _music_player := AudioStreamPlayer.new()
var _music_state := MusicState.new()
## Owned by this autoload so a fade-out outlives the screen that stopped the music.
var _music_fade: Tween
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


## Fades the ambient music in, if the music setting allows it. Calling it while the music plays changes nothing.
func start_music() -> void:
	_music_state.is_requested = true
	_apply_music_state()


func stop_music() -> void:
	_music_state.is_requested = false
	_apply_music_state()


func is_music_loaded() -> bool:
	return _music_player.stream != null


## Called at startup and on every settings change, so the saved state always applies.
func apply_settings() -> void:
	_apply_bus(MASTER_BUS, true)
	_apply_bus(SFX_BUS, Settings.is_sound_enabled)
	_apply_bus(MUSIC_BUS, Settings.is_music_enabled)
	_music_state.is_enabled = Settings.is_music_enabled
	_apply_music_state()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			_set_app_active(false)
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			_set_app_active(true)


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


func _set_app_active(is_active: bool) -> void:
	_music_state.is_app_active = is_active
	_apply_music_state()


func _apply_music_state() -> void:
	match _music_state.get_action():
		MusicState.Action.PLAY:
			_play_music()
		MusicState.Action.PAUSE:
			_pause_music()
		MusicState.Action.STOP:
			_stop_music()


func _play_music() -> void:
	if _music_player.stream == null:
		_music_player.stream = CONFIG.load_music()
		if _music_player.stream == null:
			return
	_music_player.stream_paused = false
	if not _music_player.playing:
		_music_player.volume_db = SILENT_DB
		_music_player.play()
	_fade_music_to(CONFIG.music_volume_db, CONFIG.music_fade_in_seconds)


func _pause_music() -> void:
	_cancel_music_fade()
	_music_player.stream_paused = true


func _stop_music() -> void:
	if _music_player.playing and not _music_player.stream_paused:
		_fade_music_to(SILENT_DB, CONFIG.music_fade_out_seconds).finished.connect(_release_music)
	else:
		_release_music()


func _release_music() -> void:
	_cancel_music_fade()
	_music_player.stop()
	_music_player.stream_paused = false
	_music_player.stream = null


func _fade_music_to(volume_db: float, seconds: float) -> Tween:
	_cancel_music_fade()
	_music_fade = create_tween()
	_music_fade.tween_property(_music_player, "volume_db", volume_db, seconds)
	return _music_fade


func _cancel_music_fade() -> void:
	if _music_fade != null:
		_music_fade.kill()
