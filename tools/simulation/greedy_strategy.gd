class_name GreedyStrategy
extends PlayStrategy

## The column that scores the most points now, then the one that leaves the most empty cells.

var _evaluator: MoveEvaluator


func _init(config: BalancingConfig) -> void:
	_evaluator = MoveEvaluator.new(config)


func get_strategy_name() -> String:
	return "greedy"


func choose_column(session: GameSession, tie_breaker: RandomNumberGenerator) -> int:
	var columns: Array[int] = find_playable_columns(session)
	var cell_count: int = session.board.get_column_count() * session.board.row_count
	var scores: Array[float] = []
	for column: int in columns:
		var outcome: MoveOutcome = _evaluator.evaluate(session, column)
		# Empty cells never reach cell_count + 1, so they only break ties between equal points.
		scores.append(float(outcome.points * (cell_count + 1) + outcome.count_empty_cells()))
	return pick_best_column(columns, scores, tie_breaker)
