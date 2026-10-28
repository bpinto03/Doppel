extends GutTest

## With 6 columns, a 0.3 cell axis gap and 6 rows, these cells are 100 px wide; the frame padding
## is added around them, so the frame fills the view.
const CELLS_SIZE := Vector2(630.0, 600.0)
const COLUMN_COUNT: int = 6
const MIDDLE_Y: float = 300.0
const LEFT_OUTER_COLUMN_POINT := Vector2(50.0, MIDDLE_Y)
const LEFT_AXIS_COLUMN_POINT := Vector2(250.0, MIDDLE_Y)
const RIGHT_AXIS_COLUMN_POINT := Vector2(380.0, MIDDLE_Y)
const RIGHT_MIDDLE_COLUMN_POINT := Vector2(480.0, MIDDLE_Y)
const RIGHT_OUTER_COLUMN_POINT := Vector2(580.0, MIDDLE_Y)
const BELOW_BOARD_POINT := Vector2(50.0, 650.0)
const SLIDE_STEP: float = 5.0
const GHOST_SLIDE_DURATION: float = BoardView.PLAYBACK_CONFIG.ghost_slide_duration
const POSITION_TOLERANCE: float = 0.01
const SLIDE_SAMPLED_FRAMES: int = 10
const SEED: int = 1234

var _board_view: BoardView
var _touch_zone_width: float


func before_each() -> void:
	_board_view = BoardView.new()
	_board_view.size = CELLS_SIZE + Vector2.ONE * BoardView.BOARD_STYLE.frame_padding * 2.0
	_touch_zone_width = _board_view.size.x / COLUMN_COUNT
	add_child_autofree(_board_view)
	_show_session_with_board(BoardState.new(3, 6))


func test_played_column_keeps_left_columns() -> void:
	var board := BoardState.new(3, 6)

	for column: int in board.column_count_per_side:
		assert_eq(BoardView.find_played_column(column, board), column)


func test_played_column_of_a_right_column_is_its_mirror() -> void:
	var board := BoardState.new(3, 6)

	assert_eq(BoardView.find_played_column(3, board), 2)
	assert_eq(BoardView.find_played_column(4, board), 1)
	assert_eq(BoardView.find_played_column(5, board), 0)


func test_played_column_outside_the_board_is_none() -> void:
	assert_eq(BoardView.find_played_column(BoardView.NO_COLUMN, BoardState.new(3, 6)), BoardView.NO_COLUMN)


func test_every_column_has_a_touch_zone_of_the_same_width() -> void:
	for column: int in _board_view.get_displayed_board().get_column_count():
		var zone_start: float = column * _touch_zone_width
		assert_eq(_board_view.find_touched_column(Vector2(zone_start + 1.0, MIDDLE_Y)), column)
		assert_eq(_board_view.find_touched_column(Vector2(zone_start + _touch_zone_width - 1.0, MIDDLE_Y)), column)


func test_touching_outside_the_board_hits_no_column() -> void:
	assert_eq(_board_view.find_touched_column(BELOW_BOARD_POINT), BoardView.NO_COLUMN)


func test_hovering_a_playable_left_column_shows_the_ghost() -> void:
	_move_to(LEFT_OUTER_COLUMN_POINT)

	assert_true(_board_view.is_ghost_visible())


func test_hovering_a_right_column_shows_the_ghost_of_its_mirror() -> void:
	_move_to(RIGHT_OUTER_COLUMN_POINT)

	assert_true(_board_view.is_ghost_visible())


func test_ghost_is_hidden_while_input_is_locked() -> void:
	_move_to(LEFT_OUTER_COLUMN_POINT)

	_board_view.is_input_enabled = false

	assert_false(_board_view.is_ghost_visible())


func test_releasing_on_a_left_column_plays_it() -> void:
	_press_at(LEFT_OUTER_COLUMN_POINT)
	_release_at(LEFT_OUTER_COLUMN_POINT)

	assert_signal_emitted_with_parameters(_board_view, "column_released", [0])
	assert_false(_board_view.is_ghost_visible())


func test_releasing_on_a_right_column_plays_its_mirror() -> void:
	_press_at(LEFT_OUTER_COLUMN_POINT)
	_release_at(RIGHT_MIDDLE_COLUMN_POINT)

	assert_signal_emitted_with_parameters(_board_view, "column_released", [1])


func test_pressing_alone_does_not_play() -> void:
	_press_at(LEFT_OUTER_COLUMN_POINT)

	assert_signal_not_emitted(_board_view, "column_released")
	assert_true(_board_view.is_ghost_visible())


func test_releasing_outside_the_board_cancels() -> void:
	_press_at(LEFT_OUTER_COLUMN_POINT)
	_release_at(BELOW_BOARD_POINT)

	assert_signal_not_emitted(_board_view, "column_released")


func test_right_column_whose_mirror_is_full_shows_no_ghost_and_does_not_play() -> void:
	_show_session_with_board(BoardFixture.create_board([
		". . 2 | . . .",
		". . 1 | . . .",
		". . 2 | . . .",
		". . 1 | . . .",
		". . 2 | . . .",
		". . 1 | . . .",
	]))

	_press_at(RIGHT_AXIS_COLUMN_POINT)
	var is_ghost_shown: bool = _board_view.is_ghost_visible()
	_release_at(RIGHT_AXIS_COLUMN_POINT)

	assert_false(is_ghost_shown)
	assert_signal_not_emitted(_board_view, "column_released")


func test_sliding_across_the_axis_keeps_the_ghost_visible() -> void:
	_press_at(LEFT_AXIS_COLUMN_POINT)

	var x: float = LEFT_AXIS_COLUMN_POINT.x
	while x <= RIGHT_AXIS_COLUMN_POINT.x:
		_move_to(Vector2(x, MIDDLE_Y))
		assert_true(_board_view.is_ghost_visible(), "Ghost hidden at x = %s" % x)
		x += SLIDE_STEP
	_release_at(RIGHT_AXIS_COLUMN_POINT)

	assert_signal_emitted_with_parameters(_board_view, "column_released", [2])


func test_ghost_reflection_mirrors_the_tile_across_the_axis_while_sliding() -> void:
	# The board is centered in the view, and the axis is the middle of the board.
	var axis_x: float = _board_view.size.x / 2.0
	_move_to(LEFT_OUTER_COLUMN_POINT)
	_move_to(LEFT_AXIS_COLUMN_POINT)

	for frame: int in SLIDE_SAMPLED_FRAMES:
		var tile_rect: Rect2 = _board_view.get_ghost_tile_rect()
		var reflection_rect: Rect2 = _board_view.get_ghost_reflection_rect()
		assert_almost_eq(tile_rect.position.x + reflection_rect.end.x, 2.0 * axis_x, POSITION_TOLERANCE)
		assert_almost_eq(tile_rect.position.y, reflection_rect.position.y, POSITION_TOLERANCE)
		await wait_process_frames(1)


func test_ghost_slide_ends_on_the_cell_of_the_new_column() -> void:
	_move_to(LEFT_OUTER_COLUMN_POINT)
	_move_to(RIGHT_MIDDLE_COLUMN_POINT)
	await wait_seconds(GHOST_SLIDE_DURATION * 2.0)

	assert_eq(_board_view.get_ghost_tile_rect().get_center(), _board_view.get_cell_center(Vector2i(1, 0)))
	assert_eq(_board_view.get_ghost_reflection_rect().get_center(), _board_view.get_cell_center(Vector2i(4, 0)))


func test_new_slide_starts_from_the_drawn_ghost() -> void:
	_move_to(LEFT_OUTER_COLUMN_POINT)
	_move_to(LEFT_AXIS_COLUMN_POINT)
	await wait_process_frames(1)
	var drawn_rect: Rect2 = _board_view.get_ghost_tile_rect()

	_move_to(RIGHT_MIDDLE_COLUMN_POINT)

	assert_eq(_board_view.get_ghost_tile_rect(), drawn_rect)


func test_release_plays_the_column_under_the_finger_while_the_ghost_slides() -> void:
	_press_at(LEFT_OUTER_COLUMN_POINT)
	_move_to(LEFT_AXIS_COLUMN_POINT)
	var is_ghost_on_its_cell: bool = _board_view.get_ghost_tile_rect().get_center() == _board_view.get_cell_center(Vector2i(2, 0))

	_release_at(LEFT_AXIS_COLUMN_POINT)

	assert_false(is_ghost_on_its_cell)
	assert_signal_emitted_with_parameters(_board_view, "column_released", [2])


func test_ghost_stops_animating_on_release() -> void:
	_press_at(LEFT_OUTER_COLUMN_POINT)
	_move_to(LEFT_AXIS_COLUMN_POINT)
	var was_animating: bool = _board_view.is_ghost_animating()

	_release_at(LEFT_AXIS_COLUMN_POINT)

	assert_true(was_animating)
	assert_false(_board_view.is_ghost_animating())


func test_ghost_stops_animating_when_input_is_locked() -> void:
	_move_to(LEFT_OUTER_COLUMN_POINT)

	_board_view.is_input_enabled = false

	assert_false(_board_view.is_ghost_animating())


func test_ghost_disappears_on_a_column_that_cannot_take_the_pair() -> void:
	_show_session_with_board(BoardFixture.create_board([
		". . 2 | . . .",
		". . 1 | . . .",
		". . 2 | . . .",
		". . 1 | . . .",
		". . 2 | . . .",
		". . 1 | . . .",
	]))
	_move_to(LEFT_OUTER_COLUMN_POINT)

	_move_to(RIGHT_AXIS_COLUMN_POINT)

	assert_false(_board_view.is_ghost_visible())
	assert_false(_board_view.is_ghost_animating())


func test_press_that_unlocks_the_board_plays_on_release() -> void:
	_board_view.is_input_enabled = false
	_board_view.pressed_while_locked.connect(func() -> void: _board_view.is_input_enabled = true)
	_press_at(LEFT_OUTER_COLUMN_POINT)
	_release_at(LEFT_OUTER_COLUMN_POINT)

	assert_signal_emit_count(_board_view, "pressed_while_locked", 1)
	assert_signal_emitted_with_parameters(_board_view, "column_released", [0])


func test_press_on_a_board_that_stays_locked_never_plays() -> void:
	_board_view.is_input_enabled = false
	_press_at(LEFT_OUTER_COLUMN_POINT)
	_board_view.is_input_enabled = true
	_release_at(LEFT_OUTER_COLUMN_POINT)

	assert_signal_emit_count(_board_view, "pressed_while_locked", 1)
	assert_signal_not_emitted(_board_view, "column_released")


func test_moving_tile_is_drawn_between_its_two_cells() -> void:
	var moving_tile := BoardView.MovingTile.new(1, Vector2i(2, 0), Vector2i(3, 1))
	_board_view.start_moving_tiles([moving_tile], [])
	var from_rect: Rect2 = _board_view.get_moving_tile_rect(moving_tile)
	_board_view.set_move_progress(1.0)
	var to_rect: Rect2 = _board_view.get_moving_tile_rect(moving_tile)

	_board_view.set_move_progress(0.5)

	assert_eq(_board_view.get_moving_tile_rect(moving_tile).position, from_rect.position.lerp(to_rect.position, 0.5))
	assert_gt(to_rect.position.x, from_rect.position.x)
	assert_lt(to_rect.position.y, from_rect.position.y)


func test_squashed_tile_stays_on_the_floor_of_its_cell() -> void:
	var cell := Vector2i(0, 0)
	_board_view.start_tile_scale([cell], true)
	var tile_rect: Rect2 = _board_view.get_scaled_tile_rect(cell)

	_board_view.set_tile_scale(Vector2(1.2, 0.8))
	var squashed_rect: Rect2 = _board_view.get_scaled_tile_rect(cell)

	assert_almost_eq(squashed_rect.end.y, tile_rect.end.y, 0.001)
	assert_almost_eq(squashed_rect.get_center().x, tile_rect.get_center().x, 0.001)
	assert_gt(squashed_rect.size.x, tile_rect.size.x)


func test_restricted_column_accepts_only_itself_or_its_mirror() -> void:
	_board_view.restricted_column = 2

	_move_to(LEFT_OUTER_COLUMN_POINT)
	assert_false(_board_view.is_ghost_visible())
	_move_to(RIGHT_AXIS_COLUMN_POINT)
	assert_true(_board_view.is_ghost_visible())
	_press_at(LEFT_OUTER_COLUMN_POINT)
	_release_at(LEFT_OUTER_COLUMN_POINT)
	assert_signal_not_emitted(_board_view, "column_released")
	_press_at(RIGHT_AXIS_COLUMN_POINT)
	_release_at(RIGHT_AXIS_COLUMN_POINT)
	assert_signal_emitted_with_parameters(_board_view, "column_released", [2])


func test_tutorial_hint_restricts_play_until_cleared() -> void:
	_board_view.show_tutorial_hint(TutorialScenarios.create_axis_step(), 1.0)
	assert_true(_board_view.is_tutorial_hint_shown())
	assert_eq(_board_view.restricted_column, 2)

	_board_view.clear_tutorial_hint()

	assert_false(_board_view.is_tutorial_hint_shown())
	assert_eq(_board_view.restricted_column, BoardView.NO_COLUMN)


func _show_session_with_board(board: BoardState) -> void:
	_board_view.show_session(GameSession.new(BalancingFixture.create_config(), BalancingFixture.create_seeded_rng(SEED), board))
	watch_signals(_board_view)


func _move_to(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	_board_view._gui_input(event)


func _press_at(point: Vector2) -> void:
	_board_view._gui_input(_create_button_event(point, true))


func _release_at(point: Vector2) -> void:
	_board_view._gui_input(_create_button_event(point, false))


func _create_button_event(point: Vector2, is_pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.pressed = is_pressed
	return event
