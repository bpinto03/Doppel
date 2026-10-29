extends Node

## Sends phone vibrations, following the vibration setting. Pulses requested in the same frame make one vibration, the strongest.

signal pulse_sent(pulse: HapticPulse)

const CONFIG: HapticsConfig = preload("res://data/haptics_config.tres")

var _pending_pulse: HapticPulse
var _last_sent_pulse: HapticPulse
var _last_sent_msec: int


func _ready() -> void:
	set_process(false)


func request(pulse: HapticPulse) -> void:
	if _pending_pulse == null or pulse.is_stronger_than(_pending_pulse):
		_pending_pulse = pulse
	set_process(true)


func _process(_delta: float) -> void:
	set_process(false)
	var pulse: HapticPulse = take_pending_pulse(Time.get_ticks_msec())
	if pulse != null:
		Input.vibrate_handheld(pulse.duration_ms, pulse.amplitude)


## Returns the pulse to send now, or null. Kept apart from the device call so tests never vibrate.
func take_pending_pulse(now_msec: int) -> HapticPulse:
	var pulse: HapticPulse = _pending_pulse
	_pending_pulse = null
	if pulse == null or not Settings.is_vibration_enabled or _is_too_close_to_last_pulse(pulse, now_msec):
		return null
	_last_sent_pulse = pulse
	_last_sent_msec = now_msec
	pulse_sent.emit(pulse)
	return pulse


## A stronger pulse always goes through, so a climbing chain is never lost.
func _is_too_close_to_last_pulse(pulse: HapticPulse, now_msec: int) -> bool:
	if _last_sent_pulse == null or pulse.is_stronger_than(_last_sent_pulse):
		return false
	return now_msec - _last_sent_msec < CONFIG.min_interval_ms
