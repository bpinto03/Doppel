extends Node

## Plays sound effects and music, following the sound and music settings.

var _music_player := AudioStreamPlayer.new()


func _ready() -> void:
	add_child(_music_player)
	Settings.changed.connect(_apply_music_setting)


func play_sound(stream: AudioStream) -> void:
	if not Settings.is_sound_enabled:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


func play_music(stream: AudioStream) -> void:
	_music_player.stream = stream
	_apply_music_setting()


func _apply_music_setting() -> void:
	var should_play: bool = Settings.is_music_enabled and _music_player.stream != null
	if should_play and not _music_player.playing:
		_music_player.play()
	elif not should_play:
		_music_player.stop()
