class_name HapticPulse
extends Resource

## One short vibration.

@export var duration_ms: int
## Ignored by phones that cannot set the strength, which only feel the duration.
@export_range(0.0, 1.0) var amplitude: float


## The duration decides first, since every phone feels it.
func is_stronger_than(other: HapticPulse) -> bool:
	if duration_ms != other.duration_ms:
		return duration_ms > other.duration_ms
	return amplitude > other.amplitude
