extends GutTest

const GAME_SCREEN_SCENE: PackedScene = preload("res://scenes/game/game_screen.tscn")
const BALANCING_CONFIG: BalancingConfig = preload("res://data/balancing.tres")
const TEST_SAVE_PATH: String = "user://test_app_lifecycle_save.cfg"
const SEED: int = 1234

var _save := SaveFixture.new(TEST_SAVE_PATH)


func before_each() -> void:
	_save.use_test_save()
	Settings.is_music_enabled = false
	watch_signals(AppLifecycle)


## Sent last, so no test leaves the app inactive.
func after_each() -> void:
	AppLifecycle.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	AudioManager.stop_music()
	_save.restore_player_save()
	AudioManager.apply_settings()


func test_background_and_focus_loss_make_the_app_inactive_once() -> void:
	AppLifecycle.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	AppLifecycle.notification(Node.NOTIFICATION_APPLICATION_PAUSED)

	assert_false(AppLifecycle.is_active)
	assert_signal_emit_count(AppLifecycle, "deactivated", 1)


func test_resume_makes_the_app_active_even_without_a_focus_event() -> void:
	AppLifecycle.notification(Node.NOTIFICATION_APPLICATION_PAUSED)

	AppLifecycle.notification(Node.NOTIFICATION_APPLICATION_RESUMED)

	assert_true(AppLifecycle.is_active)
	assert_signal_emit_count(AppLifecycle, "activated", 1)


func test_inactive_app_writes_the_waiting_changes_at_once() -> void:
	SaveManager.set_value(RecordBook.SECTION, RecordBook.BEST_SCORE_KEY, 42)

	AppLifecycle.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)

	var save_file := ConfigFile.new()
	assert_eq(save_file.load(TEST_SAVE_PATH), OK)
	assert_eq(save_file.get_value(RecordBook.SECTION, RecordBook.BEST_SCORE_KEY, 0), 42)


func test_inactive_app_pauses_a_game_on_the_final_state_of_its_playback() -> void:
	var game: GameScreen = _create_game_screen()
	var board_view: BoardView = game.get_node("%BoardView")
	board_view.column_released.emit(0)
	assert_false(board_view.is_input_enabled, "The playback must still be running")

	AppLifecycle.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)

	assert_eq(game.get_navigation_state(), ScreenNavigation.GameState.PAUSED)
	assert_false(board_view.is_input_enabled)
	assert_eq(BoardFixture.describe_board(board_view.get_displayed_board()), BoardFixture.describe_board(game.get_session().board))


## A finger down when the call arrives must not play a column when it lifts after the return.
func test_press_made_before_an_interruption_plays_nothing_on_release() -> void:
	var game: GameScreen = _create_game_screen()
	var board_view: BoardView = game.get_node("%BoardView")
	watch_signals(board_view)
	await wait_process_frames(1)
	var column_center: Vector2 = board_view.get_cell_center(Vector2i(0, 0))
	board_view._gui_input(_create_touch(column_center, true))

	AppLifecycle.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	AppLifecycle.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	board_view._gui_input(_create_touch(column_center, false))

	assert_signal_not_emitted(board_view, "column_released")
	assert_eq(game.get_session().placement_count, 0)


func test_inactive_app_does_not_pause_the_tutorial() -> void:
	var game: GameScreen = GAME_SCREEN_SCENE.instantiate()
	add_child_autofree(game)
	game.start_tutorial()

	AppLifecycle.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)

	assert_eq(game.get_navigation_state(), ScreenNavigation.GameState.TUTORIAL)


func _create_game_screen() -> GameScreen:
	var game: GameScreen = GAME_SCREEN_SCENE.instantiate()
	add_child_autofree(game)
	game.start_game(GameSession.new(BALANCING_CONFIG, BalancingFixture.create_seeded_rng(SEED)), RecordBook.get_best_score())
	return game


func _create_touch(position: Vector2, is_pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.pressed = is_pressed
	return event
