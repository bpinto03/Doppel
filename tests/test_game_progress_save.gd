extends GutTest

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const GAME_SCREEN_SCENE: PackedScene = preload("res://scenes/game/game_screen.tscn")
const BALANCING_CONFIG: BalancingConfig = preload("res://data/balancing.tres")
const TEST_SAVE_PATH: String = "user://test_game_progress_save.cfg"
const SEED: int = 1234
const LOW_SCORE: int = 10
const HIGH_SCORE: int = 100000

var _save := SaveFixture.new(TEST_SAVE_PATH)


func before_each() -> void:
	_save.use_test_save()
	Settings.is_music_enabled = false


func after_each() -> void:
	AudioManager.stop_music()
	_save.restore_player_save()
	AudioManager.apply_settings()


func test_each_turn_saves_the_game_before_its_playback() -> void:
	var game: GameScreen = _create_game_screen()
	game.start_new_game()

	_release_first_playable_column(game)

	assert_false((game.get_node("%BoardView") as BoardView).is_input_enabled, "The playback must still be running")
	assert_eq(_get_saved_game_data(), game.get_session().to_data())


func test_saved_game_survives_a_reload_and_draws_the_same_tiles() -> void:
	var session := GameSession.new(BALANCING_CONFIG, BalancingFixture.create_seeded_rng(SEED))
	session.play_column(0)
	CurrentGameStore.store(session, RecordBook.get_best_score())
	SaveManager.flush()

	SaveManager.load_save()
	var restored: GameSession = CurrentGameStore.load_session(BALANCING_CONFIG)

	assert_eq(restored.to_data(), session.to_data())
	session.play_column(1)
	restored.play_column(1)
	assert_eq(restored.to_data(), session.to_data())


func test_game_over_erases_the_saved_game_and_keeps_the_record() -> void:
	var game: GameScreen = _create_game_screen()
	var session := GameSession.new(BALANCING_CONFIG, BalancingFixture.create_seeded_rng(SEED), _create_board_one_pair_from_full())
	session.score = HIGH_SCORE
	CurrentGameStore.store(session, RecordBook.get_best_score())
	game.start_game(session, RecordBook.get_best_score())

	game.get_node("%BoardView").column_released.emit(0)

	assert_true(session.is_game_over)
	assert_true(SaveManager.get_section(CurrentGameStore.SECTION).is_empty())
	assert_eq(RecordBook.get_best_score(), session.score)
	assert_eq(RecordBook.get_highest_level(), session.highest_level_reached)


func test_record_never_goes_down() -> void:
	var best := GameSession.new(BALANCING_CONFIG, BalancingFixture.create_seeded_rng(SEED))
	best.score = HIGH_SCORE
	best.highest_level_reached = BALANCING_CONFIG.max_tile_level
	RecordBook.submit(best)

	RecordBook.submit(GameSession.new(BALANCING_CONFIG, BalancingFixture.create_seeded_rng(SEED)))

	assert_eq(RecordBook.get_best_score(), HIGH_SCORE)
	assert_eq(RecordBook.get_highest_level(), BALANCING_CONFIG.max_tile_level)


func test_new_game_counts_a_better_abandoned_game_for_the_record_and_replaces_it() -> void:
	SaveManager.set_value(RecordBook.SECTION, RecordBook.BEST_SCORE_KEY, LOW_SCORE)
	var abandoned: GameSession = _store_game_in_progress(HIGH_SCORE)
	var game: GameScreen = _create_game_screen()

	game.start_new_game()

	assert_eq(RecordBook.get_best_score(), HIGH_SCORE)
	assert_eq(_get_saved_game_data(), game.get_session().to_data())
	assert_ne(_get_saved_game_data(), abandoned.to_data())


func test_new_game_keeps_a_better_record_than_the_abandoned_game() -> void:
	SaveManager.set_value(RecordBook.SECTION, RecordBook.BEST_SCORE_KEY, HIGH_SCORE)
	_store_game_in_progress(LOW_SCORE)

	_create_game_screen().start_new_game()

	assert_eq(RecordBook.get_best_score(), HIGH_SCORE)


func test_tutorial_ends_on_the_home_screen_with_the_saved_game_untouched() -> void:
	var saved_game: GameSession = _store_game_in_progress(LOW_SCORE)
	var main: Node = _start_main()
	(main.get_current_screen() as HomeScreen).tutorial_requested.emit()
	var game := main.get_current_screen() as GameScreen

	_release_first_playable_column(game)
	game.get_node("%TutorialPanel").skip_requested.emit()

	assert_eq(_get_saved_game_data(), saved_game.to_data())
	assert_true((main.get_current_screen() as HomeScreen).is_choice_shown(HomeMenu.Choice.CONTINUE))


func test_back_from_the_tutorial_keeps_the_saved_game() -> void:
	var saved_game: GameSession = _store_game_in_progress(LOW_SCORE)
	var main: Node = _start_main()
	(main.get_current_screen() as HomeScreen).tutorial_requested.emit()

	main.go_back()

	assert_eq(_get_saved_game_data(), saved_game.to_data())
	assert_true((main.get_current_screen() as HomeScreen).is_choice_shown(HomeMenu.Choice.CONTINUE))


func test_back_from_a_game_offers_to_continue_it() -> void:
	var main: Node = _start_main()
	(main.get_current_screen() as HomeScreen).play_requested.emit()
	var game := main.get_current_screen() as GameScreen
	var played_game: GameSession = game.get_session()

	main.go_back()
	(game.get_node("%PausePanel").get_node("%MenuButton") as Button).pressed.emit()
	(main.get_current_screen() as HomeScreen).continue_requested.emit()

	assert_eq((main.get_current_screen() as GameScreen).get_session().to_data(), played_game.to_data())


func _create_game_screen() -> GameScreen:
	var game: GameScreen = GAME_SCREEN_SCENE.instantiate()
	add_child_autofree(game)
	return game


func _start_main() -> Node:
	var main: Node = MAIN_SCENE.instantiate()
	add_child_autofree(main)
	return main


func _store_game_in_progress(score: int) -> GameSession:
	var session := GameSession.new(BALANCING_CONFIG, BalancingFixture.create_seeded_rng(SEED))
	session.play_column(0)
	session.score = score
	CurrentGameStore.store(session, RecordBook.get_best_score())
	return session


func _release_first_playable_column(game: GameScreen) -> void:
	var board_view: BoardView = game.get_node("%BoardView")
	for column: int in game.get_session().board.column_count_per_side:
		if game.get_session().can_play_column(column) and board_view.restricted_column in [BoardView.NO_COLUMN, column]:
			board_view.column_released.emit(column)
			return
	fail_test("No playable column")


func _create_board_one_pair_from_full() -> BoardState:
	return BoardFixture.create_board([
		". 2 3 | 2 3 .",
		"2 3 2 | 3 2 3",
		"3 2 3 | 2 3 2",
		"2 3 2 | 3 2 3",
		"3 2 3 | 2 3 2",
		"2 3 2 | 3 2 3",
	])

## The saved game without the record kept beside it, to compare with GameSession.to_data().
func _get_saved_game_data() -> Dictionary[String, Variant]:
	var data: Dictionary[String, Variant] = SaveManager.get_section(CurrentGameStore.SECTION)
	data.erase(CurrentGameStore.BEST_SCORE_BEFORE_GAME_KEY)
	return data
