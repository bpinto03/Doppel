class_name HapticsConfig
extends Resource

## Vibration of each game event. See docs/balancing.md.

@export var placement: HapticPulse
## Chain link 1. Later links climb towards big_combo.
@export var merge: HapticPulse
## The cap of the climb, reached at big_combo_min_link.
@export var big_combo: HapticPulse
@export_range(2, 20) var big_combo_min_link: int
## Longer than big_combo, so the minimum interval never drops it.
@export var game_over: HapticPulse
## A pulse closer than this to the previous one is dropped unless it is stronger, so pulses never blur together.
@export var min_interval_ms: int


func get_chain_link_pulse(chain_link: int) -> HapticPulse:
	var climb: float = clampf(float(chain_link - 1) / (big_combo_min_link - 1), 0.0, 1.0)
	var pulse := HapticPulse.new()
	pulse.duration_ms = roundi(lerpf(merge.duration_ms, big_combo.duration_ms, climb))
	pulse.amplitude = lerpf(merge.amplitude, big_combo.amplitude, climb)
	return pulse
