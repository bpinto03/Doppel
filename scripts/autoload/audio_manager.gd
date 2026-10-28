extends Node

## Plays sound effects and music on their own buses, following the sound, music and volume settings.

const MASTER_BUS: StringName = &"Master"
const SFX_BUS: StringName = &"SFX"
const MUSIC_BUS: StringName = &"Music"

var _music_player := AudioStreamPlayer.new()


func _ready() -> void:
	_music_player.bus = MUSIC_BUS
	add_child(_music_player)
	Settings.changed.connect(apply_settings)
	apply_settings()


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


func _apply_music_setting() -> void:
	var should_play: bool = Settings.is_music_enabled and _music_player.stream != null
	if should_play and not _music_player.playing:
		_music_player.play()
	elif not should_play:
		_music_player.stop()
