class_name SoundEffect
extends Resource

## One sound of the game, and how much each play may differ from the others.

## Missing until a sound is chosen: playing it then does nothing.
@export var stream: AudioStream
@export var volume_offset_db: float
## Random spread around the base pitch and volume, in percent; zero keeps every play identical.
@export var pitch_variation_percent: float
@export var volume_variation_percent: float
