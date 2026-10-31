extends GutTest

const GAME_SCREEN_SCENE: PackedScene = preload("res://scenes/game/game_screen.tscn")
const MAX_WAIT_SECONDS: float = 5.0
const TEST_SAVE_PATH: String = "user://test_game_screen_tutorial_save.cfg"

var _save := SaveFixture.new(TEST_SAVE_PATH)
var _screen: Control
var _board_view: BoardView
var _tutorial_panel: TutorialPanel


## Music off in a test save, so the screen plays no music and the player's save is untouched.
func before_each() -> void:
	_save.use_test_save()
	Settings.is_music_enabled = false
	_screen = GAME_SCREEN_SCENE.instantiate()
	add_child_autofree(_screen)
	_screen.start_tutorial()
	_board_view = _screen.get_node("%BoardView")
	_tutorial_panel = _screen.get_node("%TutorialPanel")
	watch_signals(_screen)


func after_each() -> void:
	AudioManager.stop_music()
	_save.restore_player_save()
	AudioManager.apply_settings()


func test_tutorial_starts_on_the_first_step() -> void:
	assert_true(_screen.is_tutorial_running())
	assert_eq(_screen.get_tutorial_step_index(), 0)
	assert_true(_tutorial_panel.visible)
	assert_false(_tutorial_panel.is_waiting_for_next())
	assert_true(_board_view.is_tutorial_hint_shown())


func test_explanation_appears_only_once_the_playback_has_finished() -> void:
	_board_view.column_released.emit(TutorialScenarios.OUTER_LEFT_COLUMN)

	assert_false(_tutorial_panel.is_waiting_for_next())
	assert_false(_board_view.is_tutorial_hint_shown())
	await wait_for_signal(_screen.turn_playback_finished, MAX_WAIT_SECONDS)
	assert_true(_tutorial_panel.is_waiting_for_next())
	assert_false(_board_view.is_input_enabled)


func test_steps_follow_each_other_then_the_last_one_asks_for_home() -> void:
	var steps: Array[TutorialStep] = TutorialScenarios.create_steps()
	for step_index: int in steps.size():
		assert_eq(_screen.get_tutorial_step_index(), step_index)
		_board_view.column_released.emit(steps[step_index].target_column)
		await wait_for_signal(_screen.turn_playback_finished, MAX_WAIT_SECONDS)
		_tutorial_panel.next_requested.emit()

	assert_signal_emit_count(_screen, "home_requested", 1)


func test_axis_step_ends_with_the_merge_across_the_axis_on_screen() -> void:
	var steps: Array[TutorialStep] = TutorialScenarios.create_steps()
	for step_index: int in steps.size() - 1:
		_board_view.column_released.emit(steps[step_index].target_column)
		await wait_for_signal(_screen.turn_playback_finished, MAX_WAIT_SECONDS)
		_tutorial_panel.next_requested.emit()

	_board_view.column_released.emit(TutorialScenarios.AXIS_LEFT_COLUMN)
	await wait_for_signal(_screen.turn_playback_finished, MAX_WAIT_SECONDS)

	var displayed_rows: Array[String] = BoardFixture.describe_board(_board_view.get_displayed_board())
	assert_eq(displayed_rows[4], ". . . | 2 . .")
	assert_eq(displayed_rows[5], ". . 3 | 1 . .")


func test_skip_asks_for_home_at_any_time() -> void:
	_tutorial_panel.skip_requested.emit()

	assert_signal_emitted(_screen, "home_requested")


func test_press_during_a_playback_unlocks_the_board_at_once() -> void:
	_screen.start_new_game()
	_board_view.column_released.emit(TutorialScenarios.OUTER_LEFT_COLUMN)
	assert_false(_board_view.is_input_enabled)

	_board_view.pressed_while_locked.emit()

	assert_signal_emit_count(_screen, "turn_playback_finished", 1)
	assert_true(_board_view.is_input_enabled)
