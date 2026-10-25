class_name BoardView
extends Control

signal column_released(column: int)
signal pressed_while_locked

const CELL_GAP_RATIO: float = 0.06
## Width of the space around the mirror axis, in cells.
const AXIS_GAP_IN_CELLS: float = 0.3
const AXIS_COLOR := Color("#e0e4ee")
const AXIS_WIDTH: float = 6.0
const BLOCKED_COLUMN_COLOR := Color(0.0, 0.0, 0.0, 0.45)
const PULSE_COLOR := Color(1.0, 1.0, 1.0, 0.6)
const GHOST_OPACITY: float = 0.4
const GHOST_LINK_COLOR := Color(1.0, 1.0, 1.0, 0.3)
const GHOST_LINK_WIDTH: float = 3.0
const NO_COLUMN: int = -1

var is_input_enabled: bool = true:
	set(value):
		is_input_enabled = value
		queue_redraw()

var _session: GameSession
var _displayed_board: BoardState
var _hovered_column: int = NO_COLUMN
var _is_press_armed: bool
var _moving_tiles: Array[MovingTile] = []
var _move_progress: float
var _hidden_cells: Array[Vector2i] = []
var _pulsing_cells: Array[Vector2i] = []
var _pulse_strength: float


func show_session(session: GameSession) -> void:
	_session = session
	show_board(session.board)


## During playback the displayed board is a copy that only changes through ResolutionEvent.apply_to().
func show_board(board: BoardState) -> void:
	_displayed_board = board
	clear_animation()


func get_displayed_board() -> BoardState:
	return _displayed_board


## Hidden cells are drawn empty, so a falling tile does not also appear at its origin.
func start_moving_tiles(moving_tiles: Array[MovingTile], hidden_cells: Array[Vector2i]) -> void:
	_moving_tiles = moving_tiles
	_hidden_cells = hidden_cells
	set_move_progress(0.0)


func set_move_progress(progress: float) -> void:
	_move_progress = progress
	queue_redraw()


func start_pulse(cells: Array[Vector2i]) -> void:
	_pulsing_cells = cells
	set_pulse_strength(0.0)


func set_pulse_strength(strength: float) -> void:
	_pulse_strength = strength
	queue_redraw()


func clear_animation() -> void:
	_moving_tiles = []
	_hidden_cells = []
	_pulsing_cells = []
	queue_redraw()


func is_ghost_visible() -> bool:
	return is_input_enabled and _session != null and _session.can_play_column(_hovered_column)


func _gui_input(event: InputEvent) -> void:
	var motion_event := event as InputEventMouseMotion
	if motion_event != null:
		_set_hovered_column(_find_column_at(motion_event.position))
		return
	var button_event := event as InputEventMouseButton
	if button_event == null or button_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if button_event.pressed:
		_on_pressed(button_event.position)
	else:
		_on_released(button_event.position)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and not _is_press_armed:
		_set_hovered_column(NO_COLUMN)


func _on_pressed(press_position: Vector2) -> void:
	if not is_input_enabled:
		pressed_while_locked.emit()
		return
	_is_press_armed = true
	_set_hovered_column(_find_column_at(press_position))


## A press made while locked never plays on release, so skipping a playback cannot place a tile.
func _on_released(release_position: Vector2) -> void:
	if not _is_press_armed:
		return
	_is_press_armed = false
	_set_hovered_column(NO_COLUMN)
	var column: int = _find_column_at(release_position)
	if is_input_enabled and _displayed_board.is_left_column(column):
		column_released.emit(column)


func _set_hovered_column(column: int) -> void:
	if column != _hovered_column:
		_hovered_column = column
		queue_redraw()


func _draw() -> void:
	if _displayed_board == null:
		return
	for column: int in _displayed_board.get_column_count():
		for row: int in _displayed_board.row_count:
			var cell := Vector2i(column, row)
			var level: int = BoardState.EMPTY_CELL if _hidden_cells.has(cell) else _displayed_board.get_level(cell)
			TilePainter.draw_tile(self, _get_tile_rect(cell), level)
	_draw_blocked_columns()
	_draw_moving_tiles()
	_draw_pulse()
	_draw_axis()
	_draw_ghost()


func _draw_blocked_columns() -> void:
	if not is_input_enabled or _session == null:
		return
	for column: int in _displayed_board.column_count_per_side:
		if not _session.can_play_column(column):
			draw_rect(_get_column_rect(column), BLOCKED_COLUMN_COLOR)


func _draw_moving_tiles() -> void:
	for moving_tile: MovingTile in _moving_tiles:
		var row: float = lerpf(moving_tile.from_row, moving_tile.to_row, _move_progress)
		TilePainter.draw_tile(self, _get_tile_rect_at(moving_tile.column, row), moving_tile.level)


func _draw_pulse() -> void:
	var pulse_color := Color(PULSE_COLOR, PULSE_COLOR.a * _pulse_strength)
	for cell: Vector2i in _pulsing_cells:
		draw_rect(_get_tile_rect(cell), pulse_color)


func _draw_ghost() -> void:
	if not is_ghost_visible():
		return
	var preview: TilesPlacedEvent = _session.preview_placement(_hovered_column)
	var tile_rect: Rect2 = _get_tile_rect(preview.tile_cell)
	var reflection_rect: Rect2 = _get_tile_rect(preview.reflection_cell)
	var link_start := Vector2(tile_rect.end.x, tile_rect.get_center().y)
	var link_end := Vector2(reflection_rect.position.x, reflection_rect.get_center().y)
	draw_line(link_start, link_end, GHOST_LINK_COLOR, GHOST_LINK_WIDTH)
	TilePainter.draw_tile(self, tile_rect, preview.tile_level, GHOST_OPACITY)
	TilePainter.draw_tile(self, reflection_rect, preview.reflection_level, GHOST_OPACITY)


func _draw_axis() -> void:
	var axis_x: float = _get_column_x(_displayed_board.column_count_per_side) - _get_cell_size() * AXIS_GAP_IN_CELLS / 2.0
	var board_top: float = _get_board_origin().y
	var board_bottom: float = board_top + _get_cell_size() * _displayed_board.row_count
	draw_line(Vector2(axis_x, board_top), Vector2(axis_x, board_bottom), AXIS_COLOR, AXIS_WIDTH)


func _find_column_at(point: Vector2) -> int:
	if _displayed_board == null:
		return NO_COLUMN
	for column: int in _displayed_board.get_column_count():
		if _get_column_rect(column).has_point(point):
			return column
	return NO_COLUMN


func _get_cell_size() -> float:
	var width_in_cells: float = _displayed_board.get_column_count() + AXIS_GAP_IN_CELLS
	return minf(size.x / width_in_cells, size.y / _displayed_board.row_count)


func _get_board_origin() -> Vector2:
	var cell_size: float = _get_cell_size()
	var board_size := Vector2(
		(_displayed_board.get_column_count() + AXIS_GAP_IN_CELLS) * cell_size, _displayed_board.row_count * cell_size
	)
	return (size - board_size) / 2.0


func _get_column_x(column: int) -> float:
	var axis_offset: float = 0.0 if _displayed_board.is_left_column(column) else AXIS_GAP_IN_CELLS
	return _get_board_origin().x + (column + axis_offset) * _get_cell_size()


func _get_column_rect(column: int) -> Rect2:
	var height: float = _get_cell_size() * _displayed_board.row_count
	return Rect2(_get_column_x(column), _get_board_origin().y, _get_cell_size(), height)


func _get_tile_rect(cell: Vector2i) -> Rect2:
	return _get_tile_rect_at(cell.x, cell.y)


## Row is fractional while a tile is moving.
func _get_tile_rect_at(column: int, row: float) -> Rect2:
	var cell_size: float = _get_cell_size()
	var gap: float = cell_size * CELL_GAP_RATIO
	var row_from_top: float = _displayed_board.row_count - 1 - row
	var top_left := Vector2(_get_column_x(column), _get_board_origin().y + row_from_top * cell_size)
	return Rect2(top_left, Vector2.ONE * cell_size).grow(-gap / 2.0)


class MovingTile:
	var column: int
	var level: int
	var from_row: float
	var to_row: int

	func _init(tile_column: int, tile_level: int, origin_row: float, landing_row: int) -> void:
		column = tile_column
		level = tile_level
		from_row = origin_row
		to_row = landing_row
