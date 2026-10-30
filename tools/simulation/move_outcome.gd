class_name MoveOutcome
extends RefCounted

## What playing a column would do, computed on a copy of the board.

var column: int
var board_after: BoardState
var points: int
var chain_length: int


func _init(played_column: int, board: BoardState, chain_result: ChainResult) -> void:
	column = played_column
	board_after = board
	points = chain_result.points_earned
	chain_length = chain_result.chain_length


func count_empty_cells() -> int:
	return board_after.get_levels().count(BoardState.EMPTY_CELL)
