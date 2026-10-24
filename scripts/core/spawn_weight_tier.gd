class_name SpawnWeightTier
extends Resource

## Applies once the highest level reached in the game is at least this value.
@export var min_highest_level: int
## Relative draw weight per tile level.
@export var level_weights: Dictionary[int, float]
