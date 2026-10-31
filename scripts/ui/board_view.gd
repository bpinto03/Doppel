class_name BoardView
extends Control

signal column_released(column: int)
signal pressed_while_locked
signal unplayable_column_released

const BOARD_STYLE: BoardStyle = preload("res://data/board_style.tres")
const PLAYBACK_CONFIG: ResolutionPlaybackConfig = preload("res://data/resolution_playback.tres")
## Cells stretch up to this height/width ratio to fill the available height, so wider boards keep a similar size.
const MAX_CELL_HEIGHT_RATIO: float = 1.3
## Width of the space around the mirror axis, in cells.
const AXIS_GAP_IN_CELLS: float = 0.3
## Blocked columns fade into the background, on light and dark themes alike.
const BLOCKED_COLUMN_OPACITY: float = 0.6
const PULSE_COLOR := Color(1.0, 1.0, 1.0, 0.6)
const HINT_COLUMN_OPACITY: float = 0.25
const HINT_CELL_OUTLINE_WIDTH: int = 6
const HINT_AXIS_WIDTH: float = 14.0
const NO_COLUMN: int = -1

var is_input_enabled: bool = true:
	set(value):
		is_input_enabled = value
		_update_ghost()
		queue_redraw()
## When set, only this left column (or a touch on its mirror) can be played.
var restricted_column: int = NO_COLUMN:
	set(value):
		restricted_column = value
		_update_ghost()
		queue_redraw()

var tile_painter: TilePainter:
	set(value):
		tile_painter = value
		_apply_palette_to_frame_and_axis(tile_painter.palette)
		queue_redraw()

var _session: GameSession
var _displayed_board: BoardState
var _hovered_column: int = NO_COLUMN
## The played column whose ghost is drawn; it lags the hovered column only by the slide.
var _ghost_column: int = NO_COLUMN
var _ghost_tile_from := Vector2.ZERO
var _ghost_reflection_from := Vector2.ZERO
var _ghost_slide_progress: float
var _ghost_fade: float
var _ghost_pulse: float
var _ghost_slide_tween: Tween
var _ghost_fade_tween: Tween
var _ghost_pulse_tween: Tween
var _is_press_armed: bool
var _moving_tiles: Array[MovingTile] = []
var _move_progress: float
var _hidden_cells: Array[Vector2i] = []
var _scaled_cells: Array[Vector2i] = []
var _tile_scale := Vector2.ONE
var _is_scale_anchored_at_bottom: bool
var _pulsing_cells: Array[Vector2i] = []
var _pulse_strength: float
var _hint_step: TutorialStep
var _hint_strength: float
var _hint_tween: Tween
var _frame_box := StyleBoxFlat.new()
## Holds the axis and board effects, so they move with the drawn board.
var _effects_layer := Node2D.new()
var _shake_offset := Vector2.ZERO
var _axis := Panel.new()
var _axis_box := StyleBoxFlat.new()


func _ready() -> void:
	_frame_box.set_corner_radius_all(BOARD_STYLE.frame_corner_radius)
	_frame_box.set_border_width_all(BOARD_STYLE.frame_border_width)
	_axis_box.set_corner_radius_all(ceili(BOARD_STYLE.axis_width / 2.0))
	_axis.add_theme_stylebox_override(&"panel", _axis_box)
	_axis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_axis.visible = false
	_effects_layer.add_child(_axis)
	add_child(_effects_layer)
	move_child(_effects_layer, 0)


func add_board_effect(effect: Node2D) -> void:
	_effects_layer.add_child(effect)


## Moves the drawn board and its effects without touching the layout.
func set_shake_offset(offset: Vector2) -> void:
	_shake_offset = offset
	_effects_layer.position = offset
	queue_redraw()


func get_shake_offset() -> Vector2:
	return _shake_offset


func get_cell_center(cell: Vector2i) -> Vector2:
	return _get_tile_rect(cell).get_center()


func get_cell_width() -> float:
	return _get_cell_size().x


func show_session(session: GameSession) -> void:
	_session = session
	show_board(session.board)
	_update_ghost()


## During playback the displayed board is a copy that only changes through ResolutionEvent.apply_to().
func show_board(board: BoardState) -> void:
	_displayed_board = board
	clear_animation()
	_place_axis()


func get_displayed_board() -> BoardState:
	return _displayed_board


## Hidden cells are drawn empty, so a falling tile does not also appear at its origin.
func start_moving_tiles(moving_tiles: Array[MovingTile], hidden_cells: Array[Vector2i]) -> void:
	_moving_tiles = moving_tiles
	_hidden_cells = hidden_cells
	set_move_progress(0.0)


## Interpolated in pixels, so a tile can also move sideways or across the axis.
func get_moving_tile_rect(moving_tile: MovingTile) -> Rect2:
	var from_rect: Rect2 = _get_tile_rect(moving_tile.from_cell)
	return Rect2(from_rect.position.lerp(_get_tile_rect(moving_tile.to_cell).position, _move_progress), from_rect.size)


func set_move_progress(progress: float) -> void:
	_move_progress = progress
	queue_redraw()


## Bottom-anchored scaling keeps a landing tile on the floor; centered scaling makes it pop in place.
func start_tile_scale(cells: Array[Vector2i], is_anchored_at_bottom: bool) -> void:
	_scaled_cells = cells
	_is_scale_anchored_at_bottom = is_anchored_at_bottom
	set_tile_scale(Vector2.ONE)


func set_tile_scale(tile_scale: Vector2) -> void:
	_tile_scale = tile_scale
	queue_redraw()


func get_scaled_tile_rect(cell: Vector2i) -> Rect2:
	var rect: Rect2 = _get_tile_rect(cell)
	var scaled_size: Vector2 = rect.size * _tile_scale
	var anchor_y: float = rect.end.y if _is_scale_anchored_at_bottom else rect.get_center().y
	var anchor_height: float = scaled_size.y if _is_scale_anchored_at_bottom else scaled_size.y / 2.0
	return Rect2(Vector2(rect.get_center().x - scaled_size.x / 2.0, anchor_y - anchor_height), scaled_size)


func start_pulse(cells: Array[Vector2i]) -> void:
	_pulsing_cells = cells
	set_pulse_strength(0.0)


func set_pulse_strength(strength: float) -> void:
	_pulse_strength = strength
	queue_redraw()


func clear_animation() -> void:
	_moving_tiles = []
	_hidden_cells = []
	_scaled_cells = []
	_pulsing_cells = []
	queue_redraw()


## Pulses the step's target column and its mirror, its highlighted cells and, if asked, the axis,
## and restricts play to the target column.
func show_tutorial_hint(step: TutorialStep, pulse_period: float) -> void:
	_stop_hint_pulse()
	_hint_step = step
	restricted_column = step.target_column
	_hint_tween = create_tween().set_loops()
	_hint_tween.tween_method(_set_hint_progress, 0.0, 1.0, pulse_period)


func clear_tutorial_hint() -> void:
	_stop_hint_pulse()
	_hint_step = null
	restricted_column = NO_COLUMN


func is_tutorial_hint_shown() -> bool:
	return _hint_step != null


## Touching a right column plays its mirror: the tile always lands on the left.
static func find_played_column(touched_column: int, board: BoardState) -> int:
	if touched_column == NO_COLUMN or board.is_left_column(touched_column):
		return touched_column
	return board.get_mirror_column(touched_column)


## Touch zones split the whole frame width, axis gap included, into equal parts,
## so every column is as easy to hit and crossing the axis never leaves a zone.
func find_touched_column(point: Vector2) -> int:
	if _displayed_board == null:
		return NO_COLUMN
	var board_rect: Rect2 = _get_frame_rect()
	if not board_rect.has_point(point):
		return NO_COLUMN
	var zone_width: float = board_rect.size.x / _displayed_board.get_column_count()
	return floori((point.x - board_rect.position.x) / zone_width)


func is_ghost_visible() -> bool:
	return _ghost_column != NO_COLUMN


func is_ghost_animating() -> bool:
	for tween: Tween in [_ghost_slide_tween, _ghost_fade_tween, _ghost_pulse_tween]:
		if tween != null and tween.is_valid():
			return true
	return false


func get_ghost_tile_rect() -> Rect2:
	return _get_ghost_rect(_session.preview_placement(_ghost_column).tile_cell, _ghost_tile_from)


func get_ghost_reflection_rect() -> Rect2:
	return _get_ghost_rect(_session.preview_placement(_ghost_column).reflection_cell, _ghost_reflection_from)


func _gui_input(event: InputEvent) -> void:
	var motion_event := event as InputEventMouseMotion
	if motion_event != null:
		_set_hovered_column(_find_played_column_at(motion_event.position))
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
	elif what == NOTIFICATION_RESIZED:
		_place_axis()


## Forgets a finger still down, so its release after an interruption plays nothing.
func cancel_press() -> void:
	_is_press_armed = false
	_set_hovered_column(NO_COLUMN)


## A skipped playback unlocks the board at once, so the same press can play; in the tutorial it stays locked.
func _on_pressed(press_position: Vector2) -> void:
	if not is_input_enabled:
		pressed_while_locked.emit()
	if not is_input_enabled:
		return
	_is_press_armed = true
	_set_hovered_column(_find_played_column_at(press_position))


## Only a press made on an unlocked board plays on release.
func _on_released(release_position: Vector2) -> void:
	if not _is_press_armed:
		return
	_is_press_armed = false
	_set_hovered_column(NO_COLUMN)
	var column: int = _find_played_column_at(release_position)
	if not is_input_enabled or column == NO_COLUMN:
		return
	if _is_column_selectable(column):
		column_released.emit(column)
	else:
		unplayable_column_released.emit()


func _is_column_selectable(column: int) -> bool:
	var is_allowed: bool = restricted_column == NO_COLUMN or column == restricted_column
	return is_allowed and _session != null and _session.can_play_column(column)


func _find_played_column_at(point: Vector2) -> int:
	return find_played_column(find_touched_column(point), _displayed_board)


func _set_hovered_column(column: int) -> void:
	_hovered_column = column
	_update_ghost()


## The ghost follows the hovered column only while that column can be played.
func _update_ghost() -> void:
	var column: int = _hovered_column if is_input_enabled and _is_column_selectable(_hovered_column) else NO_COLUMN
	if column == _ghost_column:
		return
	if column == NO_COLUMN:
		_hide_ghost()
	elif _ghost_column == NO_COLUMN:
		_show_ghost(column)
	else:
		_slide_ghost(column)
	queue_redraw()


func _show_ghost(column: int) -> void:
	_ghost_column = column
	_ghost_slide_progress = 1.0
	_ghost_fade_tween = create_tween()
	_ghost_fade_tween.tween_method(_set_ghost_fade, 0.0, 1.0, PLAYBACK_CONFIG.ghost_fade_in_duration)
	_ghost_pulse_tween = create_tween().set_loops()
	_ghost_pulse_tween.tween_method(_set_ghost_pulse_progress, 0.0, 1.0, PLAYBACK_CONFIG.ghost_pulse_period)


## Starts from where the ghost is drawn, so a slide interrupted by another column change never jumps.
func _slide_ghost(column: int) -> void:
	_ghost_tile_from = get_ghost_tile_rect().position
	_ghost_reflection_from = get_ghost_reflection_rect().position
	_ghost_column = column
	_kill_tween(_ghost_slide_tween)
	_ghost_slide_progress = 0.0
	_ghost_slide_tween = create_tween()
	_ghost_slide_tween.tween_method(_set_ghost_slide_progress, 0.0, 1.0, PLAYBACK_CONFIG.ghost_slide_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _hide_ghost() -> void:
	_ghost_column = NO_COLUMN
	for tween: Tween in [_ghost_slide_tween, _ghost_fade_tween, _ghost_pulse_tween]:
		_kill_tween(tween)
	_ghost_slide_tween = null
	_ghost_fade_tween = null
	_ghost_pulse_tween = null


func _kill_tween(tween: Tween) -> void:
	if tween != null:
		tween.kill()


## Both rects slide with the same progress from mirrored positions, so they stay mirror images.
func _get_ghost_rect(cell: Vector2i, from_position: Vector2) -> Rect2:
	var cell_rect: Rect2 = _get_tile_rect(cell)
	return Rect2(from_position.lerp(cell_rect.position, _ghost_slide_progress), cell_rect.size)


func _set_ghost_slide_progress(progress: float) -> void:
	_ghost_slide_progress = progress
	queue_redraw()


func _set_ghost_fade(fade: float) -> void:
	_ghost_fade = fade
	queue_redraw()


## Full opacity at the start of each period, dipping smoothly in between.
func _set_ghost_pulse_progress(progress: float) -> void:
	_ghost_pulse = 1.0 - PLAYBACK_CONFIG.ghost_pulse_depth * (1.0 - cos(progress * TAU)) / 2.0
	queue_redraw()


func _draw() -> void:
	if _displayed_board == null or tile_painter == null:
		return
	draw_set_transform(_shake_offset)
	_frame_box.draw(get_canvas_item(), _get_frame_rect())
	# Empty cells first, so no cell covers the glow of a neighboring tile.
	for is_tile_pass: bool in [false, true]:
		for column: int in _displayed_board.get_column_count():
			for row: int in _displayed_board.row_count:
				var cell := Vector2i(column, row)
				var is_drawn_elsewhere: bool = _hidden_cells.has(cell) or _scaled_cells.has(cell)
				var level: int = BoardState.EMPTY_CELL if is_drawn_elsewhere else _displayed_board.get_level(cell)
				if (level != BoardState.EMPTY_CELL) == is_tile_pass:
					tile_painter.draw_tile(self, _get_tile_rect(cell), level)
	_draw_scaled_tiles()
	_draw_blocked_columns()
	_draw_moving_tiles()
	_draw_pulse()
	_draw_tutorial_hint()
	_draw_ghost()


## Both halves of a blocked pair are dimmed, since either one can be touched.
func _draw_blocked_columns() -> void:
	if not is_input_enabled or _session == null:
		return
	var blocked_color := Color(tile_painter.palette.background, BLOCKED_COLUMN_OPACITY)
	for column: int in _displayed_board.column_count_per_side:
		if not _is_column_selectable(column):
			draw_rect(_get_column_rect(column), blocked_color)
			draw_rect(_get_column_rect(_displayed_board.get_mirror_column(column)), blocked_color)


func _draw_tutorial_hint() -> void:
	if _hint_step == null:
		return
	var column_color := Color(tile_painter.palette.highlight, HINT_COLUMN_OPACITY * _hint_strength)
	draw_rect(_get_column_rect(_hint_step.target_column), column_color)
	draw_rect(_get_column_rect(_displayed_board.get_mirror_column(_hint_step.target_column)), column_color)
	var outline_color := Color(tile_painter.palette.highlight, _hint_strength)
	for cell: Vector2i in _hint_step.highlighted_cells:
		tile_painter.draw_tile_shape(self, _get_tile_rect(cell), outline_color, HINT_CELL_OUTLINE_WIDTH)
	if _hint_step.is_axis_highlighted:
		_draw_axis_line(outline_color, HINT_AXIS_WIDTH)


## Drawn after the grid, so a growing tile overlaps its neighbors.
func _draw_scaled_tiles() -> void:
	for cell: Vector2i in _scaled_cells:
		tile_painter.draw_tile(self, get_scaled_tile_rect(cell), _displayed_board.get_level(cell))


func _draw_moving_tiles() -> void:
	for moving_tile: MovingTile in _moving_tiles:
		tile_painter.draw_tile(self, get_moving_tile_rect(moving_tile), moving_tile.level)


func _draw_pulse() -> void:
	var pulse_color := Color(PULSE_COLOR, PULSE_COLOR.a * _pulse_strength)
	for cell: Vector2i in _pulsing_cells:
		tile_painter.draw_tile_shape(self, _get_tile_rect(cell), pulse_color)


func _draw_ghost() -> void:
	if not is_ghost_visible():
		return
	var preview: TilesPlacedEvent = _session.preview_placement(_ghost_column)
	var tile_rect: Rect2 = _get_ghost_rect(preview.tile_cell, _ghost_tile_from)
	var reflection_rect: Rect2 = _get_ghost_rect(preview.reflection_cell, _ghost_reflection_from)
	var opacity: float = _ghost_fade * _ghost_pulse
	var link_start := Vector2(tile_rect.end.x, tile_rect.get_center().y)
	var link_end := Vector2(reflection_rect.position.x, reflection_rect.get_center().y)
	var link_color := Color(tile_painter.palette.text, PLAYBACK_CONFIG.ghost_link_opacity * opacity)
	draw_line(link_start, link_end, link_color, PLAYBACK_CONFIG.ghost_link_width * get_cell_width())
	_draw_ghost_tile(tile_rect, preview.tile_level, opacity)
	_draw_ghost_tile(reflection_rect, preview.reflection_level, opacity)


func _draw_ghost_tile(rect: Rect2, level: int, opacity: float) -> void:
	var fill_opacity: float = PLAYBACK_CONFIG.ghost_fill_opacity * opacity
	var outline_opacity: float = PLAYBACK_CONFIG.ghost_outline_opacity * opacity
	tile_painter.draw_ghost_tile(self, rect, level, fill_opacity, outline_opacity, PLAYBACK_CONFIG.ghost_outline_width)


func _draw_axis_line(color: Color, width: float) -> void:
	var axis_rect: Rect2 = _get_axis_rect(width)
	draw_line(Vector2(axis_rect.get_center().x, axis_rect.position.y), Vector2(axis_rect.get_center().x, axis_rect.end.y), color, width)


func _apply_palette_to_frame_and_axis(palette: ThemePalette) -> void:
	_frame_box.bg_color = palette.frame_fill
	_frame_box.border_color = palette.frame_border
	_frame_box.shadow_color = Color(palette.frame_border, palette.glow_opacity)
	_frame_box.shadow_size = BOARD_STYLE.frame_glow_size if palette.glow_opacity > 0.0 else 0
	_axis_box.bg_color = palette.axis
	_axis_box.shadow_color = Color(palette.axis, palette.glow_opacity)
	_axis_box.shadow_size = BOARD_STYLE.axis_glow_size if palette.glow_opacity > 0.0 else 0


func _place_axis() -> void:
	_axis.visible = _displayed_board != null
	if _axis.visible:
		var axis_rect: Rect2 = _get_axis_rect(BOARD_STYLE.axis_width)
		_axis.position = axis_rect.position
		_axis.size = axis_rect.size


func _get_axis_rect(width: float) -> Rect2:
	var axis_x: float = _get_column_x(_displayed_board.column_count_per_side) - _get_cell_size().x * AXIS_GAP_IN_CELLS / 2.0
	var board_rect: Rect2 = _get_board_rect()
	return Rect2(axis_x - width / 2.0, board_rect.position.y, width, board_rect.size.y)


## Rises and falls back once per period.
func _set_hint_progress(progress: float) -> void:
	_hint_strength = sin(progress * PI)
	queue_redraw()


func _stop_hint_pulse() -> void:
	if _hint_tween != null:
		_hint_tween.kill()
		_hint_tween = null
	_hint_strength = 0.0
	queue_redraw()


func _get_cell_size() -> Vector2:
	var cells_area: Vector2 = size - Vector2.ONE * BOARD_STYLE.frame_padding * 2.0
	var width_in_cells: float = _displayed_board.get_column_count() + AXIS_GAP_IN_CELLS
	var height_limited_size: float = cells_area.y / _displayed_board.row_count
	var cell_width: float = minf(cells_area.x / width_in_cells, height_limited_size)
	var cell_height: float = minf(height_limited_size, cell_width * MAX_CELL_HEIGHT_RATIO)
	return Vector2(cell_width, cell_height)


func _get_board_rect() -> Rect2:
	var cell_size: Vector2 = _get_cell_size()
	var board_size := Vector2(
		(_displayed_board.get_column_count() + AXIS_GAP_IN_CELLS) * cell_size.x, _displayed_board.row_count * cell_size.y
	)
	return Rect2((size - board_size) / 2.0, board_size)


func _get_frame_rect() -> Rect2:
	return _get_board_rect().grow(BOARD_STYLE.frame_padding)


func _get_board_origin() -> Vector2:
	return _get_board_rect().position


func _get_column_x(column: int) -> float:
	var axis_offset: float = 0.0 if _displayed_board.is_left_column(column) else AXIS_GAP_IN_CELLS
	return _get_board_origin().x + (column + axis_offset) * _get_cell_size().x


func _get_column_rect(column: int) -> Rect2:
	var cell_size: Vector2 = _get_cell_size()
	return Rect2(_get_column_x(column), _get_board_origin().y, cell_size.x, cell_size.y * _displayed_board.row_count)


func _get_tile_rect(cell: Vector2i) -> Rect2:
	var cell_size: Vector2 = _get_cell_size()
	var gap: float = cell_size.x * BOARD_STYLE.cell_gap_ratio
	var row_from_top: int = _displayed_board.row_count - 1 - cell.y
	var top_left := Vector2(_get_column_x(cell.x), _get_board_origin().y + row_from_top * cell_size.y)
	return Rect2(top_left, cell_size).grow(-gap / 2.0)


class MovingTile:
	var level: int
	var from_cell: Vector2i
	var to_cell: Vector2i

	func _init(tile_level: int, origin_cell: Vector2i, destination_cell: Vector2i) -> void:
		level = tile_level
		from_cell = origin_cell
		to_cell = destination_cell
