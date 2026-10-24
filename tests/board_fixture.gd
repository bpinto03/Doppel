class_name BoardFixture
extends RefCounted

## Boards are written top row first, one digit-or-dot per cell, with "|" as the mirror axis:
## ". . . | . . ."
## "1 2 . | . 2 1"

const EMPTY_SYMBOL: String = "."
const AXIS_SYMBOL: String = "|"


static func create_board(rows_from_top: Array[String]) -> BoardState:
	var first_row_cells: PackedStringArray = _split_cells(rows_from_top[0])
	var board := BoardState.new(first_row_cells.size() / 2, rows_from_top.size())
	for top_index: int in rows_from_top.size():
		var row: int = rows_from_top.size() - 1 - top_index
		var cells: PackedStringArray = _split_cells(rows_from_top[top_index])
		for column: int in cells.size():
			if cells[column] != EMPTY_SYMBOL:
				board.set_level(Vector2i(column, row), int(cells[column]))
	return board


static func describe_board(board: BoardState) -> Array[String]:
	var rows_from_top: Array[String] = []
	for row: int in range(board.row_count - 1, -1, -1):
		var symbols: PackedStringArray = []
		for column: int in board.get_column_count():
			if column == board.column_count_per_side:
				symbols.append(AXIS_SYMBOL)
			var level: int = board.get_level(Vector2i(column, row))
			symbols.append(EMPTY_SYMBOL if level == BoardState.EMPTY_CELL else str(level))
		rows_from_top.append(" ".join(symbols))
	return rows_from_top


static func _split_cells(row_text: String) -> PackedStringArray:
	var cells: PackedStringArray = []
	for symbol: String in row_text.split(" ", false):
		if symbol != AXIS_SYMBOL:
			cells.append(symbol)
	return cells
