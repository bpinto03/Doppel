class_name ResolutionPlaybackConfig
extends Resource

## Durations in seconds.
@export var drop_duration: float
@export var fall_duration: float
@export var merge_pulse_duration: float
@export var step_pause: float
## Longer turns play faster, all steps scaled by the same factor, to fit in this duration.
@export var max_chain_duration: float
