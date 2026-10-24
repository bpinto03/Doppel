class_name BoardView
extends Control

signal column_tapped(column: int)

const CELL_GAP_RATIO: float = 0.06
## Width of the space around the mirror axis, in cells.
const AXIS_GAP_IN_CELLS: float = 0.3
const AXIS_COLOR := Color("#e0e4ee")
const AXIS_WIDTH: float = 6.0
const BLOCKED_COLUMN_COLOR := Color(0.0, 0.0, 0.0, 0.45)

var _session: GameSession


func show_session(session: GameSession) -> void:
	_session = session
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	var column: int = _find_column_at(mouse_event.position.x)
	if _session != null and _session.board.is_left_column(column):
		column_tapped.emit(column)


func _draw() -> void:
	if _session == null:
		return
	var board: BoardState = _session.board
	for column: int in board.get_column_count():
		for row: int in board.row_count:
			TilePainter.draw_tile(self, _get_tile_rect(Vector2i(column, row)), board.get_level(Vector2i(column, row)))
		if board.is_left_column(column) and not _session.can_play_column(column):
			draw_rect(_get_column_rect(column), BLOCKED_COLUMN_COLOR)
	_draw_axis()


func _draw_axis() -> void:
	var axis_x: float = _get_column_x(_session.board.column_count_per_side) - _get_cell_size() * AXIS_GAP_IN_CELLS / 2.0
	var board_top: float = _get_board_origin().y
	var board_bottom: float = board_top + _get_cell_size() * _session.board.row_count
	draw_line(Vector2(axis_x, board_top), Vector2(axis_x, board_bottom), AXIS_COLOR, AXIS_WIDTH)


func _find_column_at(x: float) -> int:
	if _session == null:
		return -1
	for column: int in _session.board.get_column_count():
		var column_x: float = _get_column_x(column)
		if x >= column_x and x < column_x + _get_cell_size():
			return column
	return -1


func _get_cell_size() -> float:
	var board: BoardState = _session.board
	var width_in_cells: float = board.get_column_count() + AXIS_GAP_IN_CELLS
	return minf(size.x / width_in_cells, size.y / board.row_count)


func _get_board_origin() -> Vector2:
	var board: BoardState = _session.board
	var cell_size: float = _get_cell_size()
	var board_size := Vector2((board.get_column_count() + AXIS_GAP_IN_CELLS) * cell_size, board.row_count * cell_size)
	return (size - board_size) / 2.0


func _get_column_x(column: int) -> float:
	var axis_offset: float = 0.0 if _session.board.is_left_column(column) else AXIS_GAP_IN_CELLS
	return _get_board_origin().x + (column + axis_offset) * _get_cell_size()


func _get_column_rect(column: int) -> Rect2:
	var height: float = _get_cell_size() * _session.board.row_count
	return Rect2(_get_column_x(column), _get_board_origin().y, _get_cell_size(), height)


func _get_tile_rect(cell: Vector2i) -> Rect2:
	var cell_size: float = _get_cell_size()
	var gap: float = cell_size * CELL_GAP_RATIO
	var row_from_top: int = _session.board.row_count - 1 - cell.y
	var top_left := Vector2(_get_column_x(cell.x), _get_board_origin().y + row_from_top * cell_size)
	return Rect2(top_left, Vector2.ONE * cell_size).grow(-gap / 2.0)
