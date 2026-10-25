class_name TutorialStep
extends RefCounted

## Tutorial games use their own rules so they never depend on data/balancing.tres tuning.
const COLUMN_COUNT_PER_SIDE: int = 3
const ROW_COUNT: int = 6
const MAX_TILE_LEVEL: int = 12
const CHAIN_MULTIPLIER_STEP: float = 1.0
## Drawn once the scripted tiles run out, so the next preview stays predictable.
const FALLBACK_TILE_LEVEL: int = 1

var instruction_key: StringName
var explanation_key: StringName
var initial_levels: Dictionary[Vector2i, int]
var tile_levels: Array[int]
var target_column: int
var highlighted_cells: Array[Vector2i]
var is_axis_highlighted: bool


func _init(
	instruction: StringName,
	explanation: StringName,
	levels_by_cell: Dictionary[Vector2i, int],
	scripted_tile_levels: Array[int],
	column_to_play: int,
	cells_to_highlight: Array[Vector2i] = [],
	highlights_axis: bool = false,
) -> void:
	instruction_key = instruction
	explanation_key = explanation
	initial_levels = levels_by_cell
	tile_levels = scripted_tile_levels
	target_column = column_to_play
	highlighted_cells = cells_to_highlight
	is_axis_highlighted = highlights_axis


static func create_config() -> BalancingConfig:
	var config := BalancingConfig.new()
	config.column_count_per_side = COLUMN_COUNT_PER_SIDE
	config.row_count = ROW_COUNT
	config.max_tile_level = MAX_TILE_LEVEL
	var fallback_tier := SpawnWeightTier.new()
	fallback_tier.level_weights = {FALLBACK_TILE_LEVEL: 1.0}
	config.spawn_weight_tiers = [fallback_tier]
	config.chain_multiplier_step = CHAIN_MULTIPLIER_STEP
	config.large_group_bonus_per_extra_tile = 0
	config.is_distorted_reflection_enabled = false
	return config


func create_session() -> GameSession:
	var board := BoardState.new(COLUMN_COUNT_PER_SIDE, ROW_COUNT)
	for cell: Vector2i in initial_levels:
		board.set_level(cell, initial_levels[cell])
	return GameSession.new(create_config(), RandomNumberGenerator.new(), board, tile_levels)
