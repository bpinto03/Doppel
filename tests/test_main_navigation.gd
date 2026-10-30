extends GutTest

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const BALANCING_CONFIG: BalancingConfig = preload("res://data/balancing.tres")
const TEST_SAVE_PATH: String = "user://test_main_navigation_save.cfg"
const SEED: int = 1234

var _save := SaveFixture.new(TEST_SAVE_PATH)


## Music off in the test save, so starting the app plays nothing.
func before_each() -> void:
	_save.use_test_save()
	Settings.is_music_enabled = false


func after_each() -> void:
	AudioManager.stop_music()
	_save.restore_player_save()
	AudioManager.apply_settings()


func test_launch_shows_the_home_screen_with_play_only() -> void:
	var main: Node = _start_main()

	var home := main.get_current_screen() as HomeScreen
	assert_not_null(home)
	assert_true(home.is_choice_shown(HomeMenu.Choice.PLAY))
	assert_false(home.is_choice_shown(HomeMenu.Choice.CONTINUE))


func test_saved_game_in_progress_offers_continue() -> void:
	_store_game(_create_game_in_progress().to_data())

	var home := _start_main().get_current_screen() as HomeScreen

	assert_true(home.is_choice_shown(HomeMenu.Choice.PLAY))
	assert_true(home.is_choice_shown(HomeMenu.Choice.CONTINUE))


func test_invalid_saved_game_is_discarded_and_the_rest_of_the_save_kept() -> void:
	var data: Dictionary[String, Variant] = _create_game_in_progress().to_data()
	data[TileGenerator.CURRENT_LEVEL_KEY] = BALANCING_CONFIG.max_tile_level + 1
	_store_game(data)
	SaveManager.set_value(RecordBook.SECTION, RecordBook.BEST_SCORE_KEY, 321)
	Settings.is_vibration_enabled = false

	var home := _start_main().get_current_screen() as HomeScreen

	assert_false(home.is_choice_shown(HomeMenu.Choice.CONTINUE))
	assert_true(SaveManager.get_section(CurrentGameStore.SECTION).is_empty())
	assert_eq(RecordBook.get_best_score(), 321)
	assert_false(Settings.is_vibration_enabled)


func test_finished_saved_game_is_not_offered() -> void:
	var data: Dictionary[String, Variant] = _create_game_in_progress().to_data()
	data[GameSession.BOARD_LEVELS_KEY] = _create_full_board_levels()
	data[GameSession.HIGHEST_LEVEL_KEY] = BALANCING_CONFIG.max_tile_level
	_store_game(data)

	var home := _start_main().get_current_screen() as HomeScreen

	assert_false(home.is_choice_shown(HomeMenu.Choice.CONTINUE))


func test_first_play_opens_the_tutorial_and_the_next_one_a_game() -> void:
	var main: Node = _start_main()

	(main.get_current_screen() as HomeScreen).play_requested.emit()
	assert_true((main.get_current_screen() as GameScreen).is_tutorial_running())
	main.go_back()
	(main.get_current_screen() as HomeScreen).play_requested.emit()

	assert_false((main.get_current_screen() as GameScreen).is_tutorial_running())


func test_continue_resumes_the_saved_game() -> void:
	var saved_game: GameSession = _create_game_in_progress()
	_store_game(saved_game.to_data())
	var main: Node = _start_main()

	(main.get_current_screen() as HomeScreen).continue_requested.emit()

	var game := main.get_current_screen() as GameScreen
	assert_false(game.is_tutorial_running())
	assert_eq(game.get_session().to_data(), saved_game.to_data())


func test_back_from_a_game_returns_home() -> void:
	var main: Node = _start_main()
	(main.get_current_screen() as HomeScreen).play_requested.emit()

	main.go_back()

	assert_true(main.get_current_screen() is HomeScreen)


func test_music_request_survives_the_way_to_a_game_and_back() -> void:
	var main: Node = _start_main()

	(main.get_current_screen() as HomeScreen).play_requested.emit()
	main.go_back()
	await wait_process_frames(1)

	assert_true(AudioManager.is_music_requested())


func _start_main() -> Node:
	var main: Node = MAIN_SCENE.instantiate()
	add_child_autofree(main)
	return main


func _create_game_in_progress() -> GameSession:
	var session := GameSession.new(BALANCING_CONFIG, BalancingFixture.create_seeded_rng(SEED))
	session.play_column(0)
	session.play_column(1)
	return session


func _store_game(data: Dictionary[String, Variant]) -> void:
	for key: String in data:
		SaveManager.set_value(CurrentGameStore.SECTION, key, data[key])


## Columns alternate two levels from the bottom, so no tile touches an equal one.
func _create_full_board_levels() -> PackedInt32Array:
	var levels := PackedInt32Array()
	var column_count: int = BALANCING_CONFIG.column_count_per_side * BoardState.SIDE_COUNT
	for column: int in column_count:
		for row: int in BALANCING_CONFIG.row_count:
			levels.append(2 + (column + row) % 2)
	return levels
