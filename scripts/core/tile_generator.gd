class_name TileGenerator
extends RefCounted

var current_level: int
var next_level: int

var _config: BalancingConfig
var _rng: RandomNumberGenerator
var _scripted_levels: Array[int]


## Scripted levels are drawn first, in order; weighted draws resume once they run out.
func _init(config: BalancingConfig, rng: RandomNumberGenerator, highest_level_reached: int, scripted_levels: Array[int] = []) -> void:
	_config = config
	_rng = rng
	_scripted_levels = scripted_levels.duplicate()
	current_level = draw_level(highest_level_reached)
	next_level = draw_level(highest_level_reached)


func advance(highest_level_reached: int) -> void:
	current_level = next_level
	next_level = draw_level(highest_level_reached)


func draw_level(highest_level_reached: int) -> int:
	if not _scripted_levels.is_empty():
		return _scripted_levels.pop_front()
	var level_weights: Dictionary[int, float] = _config.find_spawn_weights(highest_level_reached)
	var levels: Array[int] = []
	var weights := PackedFloat32Array()
	for level: int in level_weights:
		levels.append(level)
		weights.append(level_weights[level])
	return levels[_rng.rand_weighted(weights)]
