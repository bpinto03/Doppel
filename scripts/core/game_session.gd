class_name GameSession
extends RefCounted

var board: BoardState
var tile_generator: TileGenerator
var score: int
var highest_level_reached: int
var placement_count: int
var is_game_over: bool

var _config: BalancingConfig
var _merge_resolver: MergeResolver


func _init(config: BalancingConfig, rng: RandomNumberGenerator) -> void:
	_config = config
	board = BoardState.new(config.column_count_per_side, config.row_count)
	tile_generator = TileGenerator.new(config, rng, highest_level_reached)
	_merge_resolver = MergeResolver.new(config)


## A tile cannot land on a full column, even if it would merge with the top tile.
func can_play_column(column: int) -> bool:
	return (
		not is_game_over
		and board.is_left_column(column)
		and not board.is_column_full(column)
		and not board.is_column_full(board.get_mirror_column(column))
	)


func is_next_reflection_distorted() -> bool:
	var next_placement_number: int = placement_count + 1
	return _config.is_distorted_reflection_enabled and next_placement_number % _config.distorted_reflection_period == 0


func get_next_reflection_level() -> int:
	var reflection_level: int = tile_generator.current_level
	if is_next_reflection_distorted():
		reflection_level += _config.distorted_reflection_level_bonus
	return mini(reflection_level, _config.max_tile_level)


func play_column(column: int) -> ChainResult:
	assert(can_play_column(column), "Column %d cannot be played" % column)
	var tile_level: int = tile_generator.current_level
	var reflection_level: int = get_next_reflection_level()
	var placed_cells: Array[Vector2i] = [
		board.drop_tile(column, tile_level),
		board.drop_tile(board.get_mirror_column(column), reflection_level),
	]
	placement_count += 1
	_register_level(maxi(tile_level, reflection_level))

	var chain_result: ChainResult = _merge_resolver.resolve_chain(board, placed_cells)
	score += chain_result.points_earned
	_register_level(chain_result.highest_level_created)
	is_game_over = not _has_playable_column()
	tile_generator.advance(highest_level_reached)
	return chain_result


func _has_playable_column() -> bool:
	for column: int in board.column_count_per_side:
		if can_play_column(column):
			return true
	return false


func _register_level(level: int) -> void:
	highest_level_reached = maxi(highest_level_reached, level)
