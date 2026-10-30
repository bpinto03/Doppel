class_name MoveEvaluator
extends RefCounted

## Plays a column on a copy of the board, so a strategy compares moves without touching the game or its random generator.

var _resolver: MergeResolver


func _init(config: BalancingConfig) -> void:
	_resolver = MergeResolver.new(config)


func evaluate(session: GameSession, column: int) -> MoveOutcome:
	var board: BoardState = session.board.duplicate_board()
	var placed_event: TilesPlacedEvent = session.preview_placement(column)
	placed_event.apply_to(board)
	var chain_result: ChainResult = _resolver.resolve_chain(board, [placed_event.tile_cell, placed_event.reflection_cell])
	return MoveOutcome.new(column, board, chain_result)
