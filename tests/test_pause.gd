extends GutTest

const GAME_SCREEN_SCENE: PackedScene = preload("res://scenes/game/game_screen.tscn")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const TEST_SAVE_PATH: String = "user://test_pause_save.cfg"
const HIGH_SCORE: int = 100000

var _save := SaveFixture.new(TEST_SAVE_PATH)


func before_each() -> void:
	_save.use_test_save()
	Settings.is_music_enabled = false
	Settings.is_sound_enabled = false


func after_each() -> void:
	AudioManager.stop_music()
	_save.restore_player_save()
	AudioManager.apply_settings()


func test_pause_button_pauses_and_resume_leaves_the_game_unchanged() -> void:
	var game: GameScreen = _create_game_screen()
	game.start_new_game()
	game.get_node("%BoardView").column_released.emit(0)
	var data_before: Dictionary[String, Variant] = game.get_session().to_data()

	(game.get_node("%PauseButton") as Button).pressed.emit()
	assert_eq(game.get_navigation_state(), ScreenNavigation.GameState.PAUSED)
	assert_false((game.get_node("%BoardView") as BoardView).is_input_enabled)
	_press_pause_button(game, "%ResumeButton")

	assert_eq(game.get_navigation_state(), ScreenNavigation.GameState.PLAYING)
	assert_true((game.get_node("%BoardView") as BoardView).is_input_enabled)
	assert_eq(game.get_session().to_data(), data_before)


func test_restart_abandons_the_game_for_a_new_one_and_counts_it_for_the_record() -> void:
	var game: GameScreen = _create_game_screen()
	game.start_new_game()
	game.get_session().score = HIGH_SCORE
	CurrentGameStore.store(game.get_session(), 0)
	var abandoned_session: GameSession = game.get_session()
	game.open_pause()

	_press_pause_button(game, "%RestartButton")

	assert_eq(game.get_navigation_state(), ScreenNavigation.GameState.PLAYING)
	assert_ne(game.get_session(), abandoned_session)
	assert_eq(RecordBook.get_best_score(), HIGH_SCORE)


func test_menu_keeps_the_game_to_continue() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	add_child_autofree(main)
	(main.get_current_screen() as HomeScreen).play_requested.emit()
	var game := main.get_current_screen() as GameScreen
	game.start_new_game()
	game.open_pause()

	_press_pause_button(game, "%MenuButton")

	var home := main.get_current_screen() as HomeScreen
	assert_not_null(home)
	assert_true(home.is_choice_shown(HomeMenu.Choice.CONTINUE))


func test_pause_button_is_hidden_in_the_tutorial() -> void:
	var game: GameScreen = _create_game_screen()

	game.start_tutorial()

	assert_false((game.get_node("%PauseButton") as Button).visible)


func _create_game_screen() -> GameScreen:
	var game: GameScreen = GAME_SCREEN_SCENE.instantiate()
	add_child_autofree(game)
	return game


func _press_pause_button(game: GameScreen, button_name: String) -> void:
	(game.get_node("%PausePanel").get_node(button_name) as Button).pressed.emit()
