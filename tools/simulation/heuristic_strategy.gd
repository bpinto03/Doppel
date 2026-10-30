class_name HeuristicStrategy
extends PlayStrategy

## Weighs the points of the move, the empty cells it leaves, the merges it prepares for the visible next tile,
## and the column pairs it leaves one cell from full. See docs/balancing.md.

const POINTS_WEIGHT: float = 1.0
const EMPTY_CELL_WEIGHT: float = 10.0
const NEXT_TILE_MERGE_WEIGHT: float = 8.0
const NEARLY_FULL_PAIR_PENALTY: float = 15.0
## A column pair with this many free cells or fewer counts as nearly full.
const NEARLY_FULL_FREE_CELLS: int = 1

var _config: BalancingConfig
var _evaluator: MoveEvaluator


func _init(config: BalancingConfig) -> void:
	_config = config
	_evaluator = MoveEvaluator.new(config)


func get_strategy_name() -> String:
	return "heuristic"


func choose_column(session: GameSession, tie_breaker: RandomNumberGenerator) -> int:
	var columns: Array[int] = find_playable_columns(session)
	var scores: Array[float] = []
	for column: int in columns:
		scores.append(score_outcome(_evaluator.evaluate(session, column), session.tile_generator.next_level))
	return pick_best_column(columns, scores, tie_breaker)


func score_outcome(outcome: MoveOutcome, next_level: int) -> float:
	return (
		POINTS_WEIGHT * outcome.points
		+ EMPTY_CELL_WEIGHT * outcome.count_empty_cells()
		+ NEXT_TILE_MERGE_WEIGHT * count_next_tile_merges(outcome.board_after, next_level)
		- NEARLY_FULL_PAIR_PENALTY * count_nearly_full_pairs(outcome.board_after)
	)


## Counts the landing cells, tile side and reflection side, where the next tile would touch a tile of its level.
## The reflection is taken undistorted: one placement in distorted_reflection_period differs.
func count_next_tile_merges(board: BoardState, next_level: int) -> int:
	var merge_count: int = 0
	for column: int in board.column_count_per_side:
		var mirror_column: int = board.get_mirror_column(column)
		if board.is_column_full(column) or board.is_column_full(mirror_column):
			continue
		var placed_board: BoardState = board.duplicate_board()
		var landing_cells: Array[Vector2i] = [placed_board.get_landing_cell(column), placed_board.get_landing_cell(mirror_column)]
		for cell: Vector2i in landing_cells:
			placed_board.set_level(cell, next_level)
		for cell: Vector2i in landing_cells:
			if _has_neighbor_of_same_level(placed_board, cell):
				merge_count += 1
	return merge_count


func count_nearly_full_pairs(board: BoardState) -> int:
	var pair_count: int = 0
	for column: int in board.column_count_per_side:
		var tallest_height: int = maxi(board.get_column_height(column), board.get_column_height(board.get_mirror_column(column)))
		if board.row_count - tallest_height <= NEARLY_FULL_FREE_CELLS:
			pair_count += 1
	return pair_count


func _has_neighbor_of_same_level(board: BoardState, cell: Vector2i) -> bool:
	for neighbor: Vector2i in board.get_orthogonal_neighbors(cell):
		if board.is_across_axis(cell, neighbor) and not _config.is_cross_axis_merge_enabled:
			continue
		if board.get_level(neighbor) == board.get_level(cell):
			return true
	return false
