class_name ResolutionPlaybackConfig
extends Resource

## Durations in seconds.

@export_group("Drop and fall")
@export var drop_duration: float
@export var fall_duration: float
@export var fall_transition: Tween.TransitionType
@export var fall_ease: Tween.EaseType
## Landed tiles get wider and shorter by this ratio of their size, then spring back.
@export var landing_squash: float
@export var landing_squash_duration: float

@export_group("Merge")
@export var merge_pulse_duration: float
## Merged tiles slide onto the result cell.
@export var merge_converge_duration: float
## The result tile grows, then comes back with a small rebound.
@export var merge_pop_duration: float
## Peak scale of the result tile on the first chain link, and at full chain intensity.
@export var merge_pop_scale: float
@export var merge_pop_max_scale: float

@export_group("Chains")
## Chain intensity from link 1 (x = 0) to chain_intensity_max_link (x = 1), between 0 and 1.
@export var chain_intensity_curve: Curve
## From this link on, chains play at full intensity.
@export var chain_intensity_max_link: int
## Merge steps of a chain link play this many times faster at full intensity.
@export var chain_max_speed_up: float

@export_group("Turn")
@export var step_pause: float
## Longer turns play faster, all steps scaled by the same factor, to fit in this duration.
@export var max_chain_duration: float


func get_chain_intensity(chain_link: int) -> float:
	var progress: float = clampf(float(chain_link - 1) / (chain_intensity_max_link - 1), 0.0, 1.0)
	return chain_intensity_curve.sample(progress)


func get_chain_speed(chain_link: int) -> float:
	return lerpf(1.0, chain_max_speed_up, get_chain_intensity(chain_link))


func get_pop_scale(chain_link: int) -> float:
	return lerpf(merge_pop_scale, merge_pop_max_scale, get_chain_intensity(chain_link))
