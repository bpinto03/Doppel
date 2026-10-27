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

@export_group("Particles")
## A burst leaves each merge result; later chain links add more particles.
@export var particles_per_merge: int
@export var particles_per_extra_link: int
@export var max_particles_per_burst: int
## Bursts never put more particles on screen at once than this.
@export var max_live_particles: int
@export var particle_lifetime: float
## Sizes, speeds and gravity are relative to the cell width, so they follow the board size.
@export var particle_min_size: float
@export var particle_max_size: float
## Cell widths per second.
@export var particle_min_speed: float
@export var particle_max_speed: float
## Cell widths per second squared.
@export var particle_gravity: float
## Particles start on a circle of this radius around the result tile center, so they leave from its edge.
@export var particle_start_radius: float

@export_group("Shake")
## From this chain link on, the board shakes; amplitudes are in cell widths.
@export var shake_min_link: int
@export var shake_amplitude: float
@export var shake_amplitude_per_link: float
@export var shake_max_amplitude: float
@export var shake_duration: float

@export_group("Combo")
## Chain link from which each word is shown, with its translation key; the highest reached wins.
@export var combo_words: Dictionary[int, String]
## The combo message pops at each new link.
@export var combo_pop_scale: float
@export var combo_pop_duration: float
## Opacity of the tile previews while a combo message is shown over them.
@export var preview_dimmed_opacity: float

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


func get_particle_count(chain_link: int) -> int:
	return mini(particles_per_merge + particles_per_extra_link * (chain_link - 1), max_particles_per_burst)


## Zero below shake_min_link.
func get_shake_amplitude(chain_link: int) -> float:
	if chain_link < shake_min_link:
		return 0.0
	return minf(shake_amplitude + shake_amplitude_per_link * (chain_link - shake_min_link), shake_max_amplitude)


## Empty below the first word link.
func get_combo_word_key(chain_link: int) -> String:
	var word_key: String = ""
	var word_link: int = 0
	for min_link: int in combo_words:
		if min_link <= chain_link and min_link > word_link:
			word_link = min_link
			word_key = combo_words[min_link]
	return word_key
