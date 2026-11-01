class_name GameOverEffectsConfig
extends Resource

## Confetti and appearance of the game over panel. Durations in seconds; lengths in pixels at the base resolution.

@export_group("Confetti")
@export var confetti_amount: int
## Used when the game beat the record.
@export var record_confetti_amount: int
## Neither burst may exceed it, so a modest phone keeps 60 FPS.
@export var max_confetti_amount: int
@export var confetti_lifetime: float
## Launched upward from the top edge of the panel, within this angle on each side, in degrees.
@export var confetti_spread: float
@export var confetti_min_speed: float
@export var confetti_max_speed: float
@export var confetti_gravity: float
## Length of a confetti piece.
@export var confetti_min_size: float
@export var confetti_max_size: float
## Spin in degrees per second, either way.
@export var confetti_max_spin: float

@export_group("Appearance")
@export var appear_duration: float
## The panel grows from this scale to its own size while it fades in.
@export var appear_start_scale: float

@export_group("Coins earned")
## The "+N" row grows back from this scale once the panel has appeared; off with screen shake.
@export var coin_pop_start_scale: float
@export var coin_pop_duration: float

@export_group("Crown halo")
## The halo turns and breathes while the panel shows, through its transform and opacity only: it is never redrawn.
## One full turn of the rays.
@export var halo_turn_duration: float
## From full opacity down to halo_min_opacity, then the same back.
@export var halo_breath_duration: float
@export var halo_min_opacity: float
