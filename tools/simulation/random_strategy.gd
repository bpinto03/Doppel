class_name RandomStrategy
extends PlayStrategy

## Any playable column, at random: the floor to compare the other strategies with.


func get_strategy_name() -> String:
	return "random"


func choose_column(session: GameSession, tie_breaker: RandomNumberGenerator) -> int:
	var columns: Array[int] = find_playable_columns(session)
	return columns[tie_breaker.randi_range(0, columns.size() - 1)]
