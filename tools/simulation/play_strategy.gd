@abstract
class_name PlayStrategy
extends RefCounted

## Chooses the column of each placement, from what the player sees: the board, the current and the next tile.
## The tie breaker is the strategy's own generator: the game's generator is never read.


@abstract func get_strategy_name() -> String


## Returns a left column the session can play.
@abstract func choose_column(session: GameSession, tie_breaker: RandomNumberGenerator) -> int


static func find_playable_columns(session: GameSession) -> Array[int]:
	var columns: Array[int] = []
	for column: int in session.board.column_count_per_side:
		if session.can_play_column(column):
			columns.append(column)
	return columns


## Equal best scores are broken by the tie breaker, so a run stays reproducible.
static func pick_best_column(columns: Array[int], scores: Array[float], tie_breaker: RandomNumberGenerator) -> int:
	var best_score: float = scores.max()
	var best_columns: Array[int] = []
	for index: int in columns.size():
		if scores[index] == best_score:
			best_columns.append(columns[index])
	return best_columns[tie_breaker.randi_range(0, best_columns.size() - 1)]
