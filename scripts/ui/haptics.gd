class_name Haptics
extends RefCounted

## Short phone vibrations, off when the vibration setting is, and never closer than the configured interval.

var _config: HapticsConfig
var _has_vibrated: bool
var _last_vibration_msec: int


func _init(config: HapticsConfig) -> void:
	_config = config


func vibrate(duration_ms: int) -> void:
	try_vibrate(duration_ms, Time.get_ticks_msec())


## Returns whether the phone was asked to vibrate.
func try_vibrate(duration_ms: int, now_msec: int) -> bool:
	if not Settings.is_vibration_enabled:
		return false
	if _has_vibrated and now_msec - _last_vibration_msec < _config.min_interval_ms:
		return false
	_has_vibrated = true
	_last_vibration_msec = now_msec
	Input.vibrate_handheld(duration_ms)
	return true
