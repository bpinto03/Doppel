extends GutTest

const GAME_SCREEN_SCENE: PackedScene = preload("res://scenes/game/game_screen.tscn")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const TEST_SAVE_PATH: String = "user://test_pause_save.cfg"
const HIGH_SCORE: int = 100000
const PAUSE_TOGGLED_SETTINGS: Dictionary[String, StringName] = {
	"%SoundToggle": &"is_sound_enabled",
	"%MusicToggle": &"is_music_enabled",
	"%VibrationToggle": &"is_vibration_enabled",
	"%ScreenShakeToggle": &"is_screen_shake_enabled",
}

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


func test_pause_settings_switch_each_toggle_and_keep_it_without_touching_the_game() -> void:
	var game: GameScreen = _create_game_screen()
	game.start_new_game()
	game.get_node("%BoardView").column_released.emit(0)
	game.open_pause()
	var data_before: Dictionary[String, Variant] = game.get_session().to_data()

	_press_pause_button(game, "%SettingsButton")
	assert_eq(game.get_navigation_state(), ScreenNavigation.GameState.PAUSE_SETTINGS)
	var rows: SettingsRows = game.get_node("%PausePanel").get_node("%SettingsRows")
	for toggle_path: String in PAUSE_TOGGLED_SETTINGS:
		var setting: StringName = PAUSE_TOGGLED_SETTINGS[toggle_path]
		var value_before: bool = Settings.get(setting)
		(rows.get_node(toggle_path) as Button).toggled.emit(not value_before)
		SaveManager.flush()
		SaveManager.load_save()
		assert_eq(Settings.get(setting), not value_before, String(setting))
	_press_pause_button(game, "%BackButton")
	_press_pause_button(game, "%ResumeButton")

	assert_eq(game.get_navigation_state(), ScreenNavigation.GameState.PLAYING)
	assert_eq(game.get_session().to_data(), data_before)


func test_pause_settings_show_only_the_toggles() -> void:
	var game: GameScreen = _create_game_screen()
	game.start_new_game()
	game.open_pause()

	_press_pause_button(game, "%SettingsButton")

	var rows: SettingsRows = game.get_node("%PausePanel").get_node("%SettingsRows")
	assert_true((rows.get_node("%Toggles") as Control).visible)
	assert_false((rows.get_node("%Language") as Control).visible)
	assert_false((rows.get_node("%Theme") as Control).visible)


func test_back_in_the_pause_settings_returns_to_the_pause_then_resumes() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	add_child_autofree(main)
	(main.get_current_screen() as HomeScreen).play_requested.emit()
	var game := main.get_current_screen() as GameScreen
	game.start_new_game()
	game.open_pause()
	_press_pause_button(game, "%SettingsButton")

	main.go_back()
	assert_eq(game.get_navigation_state(), ScreenNavigation.GameState.PAUSED)
	main.go_back()

	assert_eq(game.get_navigation_state(), ScreenNavigation.GameState.PLAYING)


func test_a_new_pause_opens_on_its_main_page() -> void:
	var game: GameScreen = _create_game_screen()
	game.start_new_game()
	game.open_pause()
	_press_pause_button(game, "%SettingsButton")
	game.close_pause()

	game.open_pause()

	assert_eq(game.get_navigation_state(), ScreenNavigation.GameState.PAUSED)


func _create_game_screen() -> GameScreen:
	var game: GameScreen = GAME_SCREEN_SCENE.instantiate()
	add_child_autofree(game)
	return game


func _press_pause_button(game: GameScreen, button_name: String) -> void:
	(game.get_node("%PausePanel").get_node(button_name) as Button).pressed.emit()
