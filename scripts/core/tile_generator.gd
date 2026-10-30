class_name TileGenerator
extends RefCounted

const CURRENT_LEVEL_KEY: String = "current_level"
const NEXT_LEVEL_KEY: String = "next_level"
const RNG_SEED_KEY: String = "rng_seed"
const RNG_STATE_KEY: String = "rng_state"

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


## Scripted levels are not included: only the tutorial uses them, and it is never saved.
func to_data() -> Dictionary[String, Variant]:
	return {
		CURRENT_LEVEL_KEY: current_level,
		NEXT_LEVEL_KEY: next_level,
		RNG_SEED_KEY: _rng.seed,
		RNG_STATE_KEY: _rng.state,
	}


## The seed is set before the state, because setting a seed resets the state.
func restore_data(data: Dictionary) -> void:
	current_level = data[CURRENT_LEVEL_KEY]
	next_level = data[NEXT_LEVEL_KEY]
	_rng.seed = data[RNG_SEED_KEY]
	_rng.state = data[RNG_STATE_KEY]


static func is_valid_data(data: Dictionary, config: BalancingConfig) -> bool:
	for key: String in [CURRENT_LEVEL_KEY, NEXT_LEVEL_KEY, RNG_SEED_KEY, RNG_STATE_KEY]:
		if not data.get(key) is int:
			return false
	return _is_drawable_level(data[CURRENT_LEVEL_KEY], config) and _is_drawable_level(data[NEXT_LEVEL_KEY], config)


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


static func _is_drawable_level(level: int, config: BalancingConfig) -> bool:
	return level > BoardState.EMPTY_CELL and level <= config.max_tile_level
