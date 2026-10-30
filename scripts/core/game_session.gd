class_name GameSession
extends RefCounted

const RULES_VERSION_KEY: String = "rules_version"
const COLUMN_COUNT_PER_SIDE_KEY: String = "column_count_per_side"
const ROW_COUNT_KEY: String = "row_count"
const BOARD_LEVELS_KEY: String = "board_levels"
const SCORE_KEY: String = "score"
const HIGHEST_LEVEL_KEY: String = "highest_level_reached"
const PLACEMENT_COUNT_KEY: String = "placement_count"

var board: BoardState
var tile_generator: TileGenerator
var score: int
var highest_level_reached: int
var placement_count: int
var is_game_over: bool

var _config: BalancingConfig
var _merge_resolver: MergeResolver


## Without an initial board, the game starts on an empty board.
func _init(config: BalancingConfig, rng: RandomNumberGenerator, initial_board: BoardState = null, scripted_levels: Array[int] = []) -> void:
	_config = config
	board = initial_board if initial_board != null else BoardState.new(config.column_count_per_side, config.row_count)
	assert(
		board.column_count_per_side == config.column_count_per_side and board.row_count == config.row_count,
		"Initial board size does not match the balancing config"
	)
	highest_level_reached = board.get_highest_level()
	tile_generator = TileGenerator.new(config, rng, highest_level_reached, scripted_levels)
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


## Where the current tile and its reflection would land, without changing the board.
func preview_placement(column: int) -> TilesPlacedEvent:
	assert(can_play_column(column), "Column %d cannot be played" % column)
	return TilesPlacedEvent.new(
		board.get_landing_cell(column),
		tile_generator.current_level,
		board.get_landing_cell(board.get_mirror_column(column)),
		get_next_reflection_level(),
		is_next_reflection_distorted(),
	)


func play_column(column: int) -> ChainResult:
	var placed_event: TilesPlacedEvent = preview_placement(column)
	placed_event.apply_to(board)
	placement_count += 1
	_register_level(maxi(placed_event.tile_level, placed_event.reflection_level))

	var chain_result: ChainResult = _merge_resolver.resolve_chain(board, [placed_event.tile_cell, placed_event.reflection_cell])
	chain_result.events.push_front(placed_event)
	score += chain_result.points_earned
	_register_level(chain_result.highest_level_created)
	is_game_over = not _has_playable_column()
	tile_generator.advance(highest_level_reached)
	return chain_result


## Plain values only (int, PackedInt32Array), so any storage can keep them exactly.
func to_data() -> Dictionary[String, Variant]:
	var data: Dictionary[String, Variant] = {
		RULES_VERSION_KEY: _config.rules_version,
		COLUMN_COUNT_PER_SIDE_KEY: board.column_count_per_side,
		ROW_COUNT_KEY: board.row_count,
		BOARD_LEVELS_KEY: board.get_levels(),
		SCORE_KEY: score,
		HIGHEST_LEVEL_KEY: highest_level_reached,
		PLACEMENT_COUNT_KEY: placement_count,
	}
	data.merge(tile_generator.to_data())
	return data


## Returns null when the data does not describe a game in progress under these rules:
## missing or mistyped value, other board size or rules version, impossible board or levels, finished game.
static func create_from_data(config: BalancingConfig, data: Dictionary) -> GameSession:
	if not _has_valid_counters(config, data) or not TileGenerator.is_valid_data(data, config):
		return null
	if not data.get(BOARD_LEVELS_KEY) is PackedInt32Array:
		return null
	var restored_board: BoardState = BoardState.create_from_levels(
		data[COLUMN_COUNT_PER_SIDE_KEY], data[ROW_COUNT_KEY], data[BOARD_LEVELS_KEY], config.max_tile_level
	)
	if restored_board == null or not restored_board.is_settled() or restored_board.get_highest_level() > data[HIGHEST_LEVEL_KEY]:
		return null
	var session := GameSession.new(config, RandomNumberGenerator.new(), restored_board)
	session.score = data[SCORE_KEY]
	session.highest_level_reached = data[HIGHEST_LEVEL_KEY]
	session.placement_count = data[PLACEMENT_COUNT_KEY]
	session.tile_generator.restore_data(data)
	if not session._has_playable_column():
		return null
	return session


static func _has_valid_counters(config: BalancingConfig, data: Dictionary) -> bool:
	for key: String in [RULES_VERSION_KEY, COLUMN_COUNT_PER_SIDE_KEY, ROW_COUNT_KEY, SCORE_KEY, HIGHEST_LEVEL_KEY, PLACEMENT_COUNT_KEY]:
		if not data.get(key) is int:
			return false
	return (
		data[RULES_VERSION_KEY] == config.rules_version
		and data[COLUMN_COUNT_PER_SIDE_KEY] == config.column_count_per_side
		and data[ROW_COUNT_KEY] == config.row_count
		and data[SCORE_KEY] >= 0
		and data[PLACEMENT_COUNT_KEY] >= 0
		and data[HIGHEST_LEVEL_KEY] <= config.max_tile_level
	)


func _has_playable_column() -> bool:
	for column: int in board.column_count_per_side:
		if can_play_column(column):
			return true
	return false


func _register_level(level: int) -> void:
	highest_level_reached = maxi(highest_level_reached, level)
