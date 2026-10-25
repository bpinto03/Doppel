extends GutTest

## With 6 columns, a 0.3 cell axis gap and 6 rows, this size gives 100 px cells and no margin.
const BOARD_VIEW_SIZE := Vector2(630.0, 600.0)
const LEFT_OUTER_COLUMN_POINT := Vector2(50.0, 300.0)
const RIGHT_INNER_COLUMN_POINT := Vector2(380.0, 300.0)
const BELOW_BOARD_POINT := Vector2(50.0, 650.0)
const SEED: int = 1234

var _board_view: BoardView


func before_each() -> void:
	_board_view = BoardView.new()
	_board_view.size = BOARD_VIEW_SIZE
	add_child_autofree(_board_view)
	_board_view.show_session(GameSession.new(BalancingFixture.create_config(), BalancingFixture.create_seeded_rng(SEED)))
	watch_signals(_board_view)


func test_hovering_a_playable_left_column_shows_the_ghost() -> void:
	_move_to(LEFT_OUTER_COLUMN_POINT)

	assert_true(_board_view.is_ghost_visible())


func test_hovering_a_right_column_shows_no_ghost() -> void:
	_move_to(RIGHT_INNER_COLUMN_POINT)

	assert_false(_board_view.is_ghost_visible())


func test_ghost_is_hidden_while_input_is_locked() -> void:
	_move_to(LEFT_OUTER_COLUMN_POINT)

	_board_view.is_input_enabled = false

	assert_false(_board_view.is_ghost_visible())


func test_releasing_on_a_left_column_plays_it() -> void:
	_press_at(LEFT_OUTER_COLUMN_POINT)
	_release_at(LEFT_OUTER_COLUMN_POINT)

	assert_signal_emitted_with_parameters(_board_view, "column_released", [0])
	assert_false(_board_view.is_ghost_visible())


func test_pressing_alone_does_not_play() -> void:
	_press_at(LEFT_OUTER_COLUMN_POINT)

	assert_signal_not_emitted(_board_view, "column_released")
	assert_true(_board_view.is_ghost_visible())


func test_releasing_on_the_right_half_cancels() -> void:
	_press_at(LEFT_OUTER_COLUMN_POINT)
	_release_at(RIGHT_INNER_COLUMN_POINT)

	assert_signal_not_emitted(_board_view, "column_released")


func test_releasing_outside_the_board_cancels() -> void:
	_press_at(LEFT_OUTER_COLUMN_POINT)
	_release_at(BELOW_BOARD_POINT)

	assert_signal_not_emitted(_board_view, "column_released")


func test_press_while_locked_requests_skip_and_its_release_never_plays() -> void:
	_board_view.is_input_enabled = false
	_press_at(LEFT_OUTER_COLUMN_POINT)
	_board_view.is_input_enabled = true
	_release_at(LEFT_OUTER_COLUMN_POINT)

	assert_signal_emit_count(_board_view, "pressed_while_locked", 1)
	assert_signal_not_emitted(_board_view, "column_released")


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
