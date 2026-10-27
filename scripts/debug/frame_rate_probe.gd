class_name FrameRateProbe
extends Node

## Debug builds only: logs the average and lowest frame rate of each turn playback,
## to read with `adb logcat -s godot`. Removed with the other debug tools in step 3.1.

var _playback: ResolutionPlayback
var _was_playing: bool
var _frame_count: int
var _total_seconds: float
var _longest_frame_seconds: float


func _init(playback: ResolutionPlayback) -> void:
	_playback = playback


func _process(delta: float) -> void:
	if _playback.is_playing:
		if not _was_playing:
			_frame_count = 0
			_total_seconds = 0.0
			_longest_frame_seconds = 0.0
		_frame_count += 1
		_total_seconds += delta
		_longest_frame_seconds = maxf(_longest_frame_seconds, delta)
	elif _was_playing and _frame_count > 0:
		print("Playback FPS: duration=%.2fs avg=%.0f min=%.0f" % [_total_seconds, _frame_count / _total_seconds, 1.0 / _longest_frame_seconds])
	_was_playing = _playback.is_playing
