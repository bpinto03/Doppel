extends GutTest

const GAME_SCREEN_SCENE: PackedScene = preload("res://scenes/game/game_screen.tscn")
const BALANCING_CONFIG: BalancingConfig = preload("res://data/balancing.tres")
const TEST_SAVE_PATH: String = "user://test_game_over_save.cfg"
const SEED: int = 1234
const PREVIOUS_BEST: int = 100
const HIGH_SCORE: int = 500

var _save := SaveFixture.new(TEST_SAVE_PATH)


func before_each() -> void:
	_save.use_test_save()
	Settings.is_music_enabled = false
	Settings.is_sound_enabled = false


func after_each() -> void:
	AudioManager.stop_music()
	_save.restore_player_save()
	AudioManager.apply_settings()


func test_a_score_above_the_previous_record_is_a_new_record() -> void:
	var summary := GameOverSummary.new(_create_session_with_score(HIGH_SCORE), PREVIOUS_BEST, HIGH_SCORE)

	assert_true(summary.is_new_record)
	assert_eq(summary.score, HIGH_SCORE)
	assert_eq(summary.best_score, HIGH_SCORE)


func test_a_score_equal_to_or_below_the_previous_record_is_not_a_new_record() -> void:
	assert_false(GameOverSummary.new(_create_session_with_score(PREVIOUS_BEST), PREVIOUS_BEST, PREVIOUS_BEST).is_new_record)
	assert_false(GameOverSummary.new(_create_session_with_score(PREVIOUS_BEST - 1), PREVIOUS_BEST, PREVIOUS_BEST).is_new_record)


func test_the_first_record_over_zero_is_not_announced() -> void:
	assert_false(GameOverSummary.new(_create_session_with_score(HIGH_SCORE), 0, HIGH_SCORE).is_new_record)


func test_finished_game_shows_the_game_over_panel_with_the_session_values() -> void:
	var game: GameScreen = _start_game_one_pair_from_end(PREVIOUS_BEST)

	_finish_the_game(game)

	var panel: GameOverPanel = game.get_node("%GameOverPanel")
	assert_true(panel.visible)
	assert_true(panel.is_new_record_shown())
	assert_eq((panel.get_node("%ScoreLabel") as Label).text, tr("UI_SCORE").format({"value": game.get_session().score}))
	assert_eq((panel.get_node("%BestLabel") as Label).text, tr("UI_BEST").format({"value": RecordBook.get_best_score()}))
	var highest_tile_value: int = MergeScoring.calculate_tile_value(game.get_session().highest_level_reached)
	assert_eq((panel.get_node("%MaxTileLabel") as Label).text, tr("UI_MAX_TILE").format({"value": highest_tile_value}))
	assert_eq(game.get_navigation_state(), ScreenNavigation.GameState.GAME_OVER)


func test_play_again_starts_a_new_game_in_one_tap() -> void:
	var game: GameScreen = _start_game_one_pair_from_end(PREVIOUS_BEST)
	_finish_the_game(game)

	(game.get_node("%GameOverPanel").get_node("%ReplayButton") as Button).pressed.emit()

	assert_false((game.get_node("%GameOverPanel") as Control).visible)
	assert_false(game.get_session().is_game_over)
	assert_eq(game.get_navigation_state(), ScreenNavigation.GameState.PLAYING)


func test_menu_asks_for_the_home_screen() -> void:
	var game: GameScreen = _start_game_one_pair_from_end(PREVIOUS_BEST)
	_finish_the_game(game)
	watch_signals(game)

	(game.get_node("%GameOverPanel").get_node("%MenuButton") as Button).pressed.emit()

	assert_signal_emitted(game, "home_requested")


func test_record_before_the_game_survives_with_the_saved_game() -> void:
	CurrentGameStore.store(_create_session_with_score(HIGH_SCORE), PREVIOUS_BEST)
	SaveManager.flush()
	SaveManager.load_save()

	assert_eq(CurrentGameStore.load_best_score_before_game(), PREVIOUS_BEST)


func test_saved_game_without_the_record_before_it_uses_the_current_record() -> void:
	SaveManager.set_value(RecordBook.SECTION, RecordBook.BEST_SCORE_KEY, PREVIOUS_BEST)

	assert_eq(CurrentGameStore.load_best_score_before_game(), PREVIOUS_BEST)


func _create_session_with_score(score: int) -> GameSession:
	var session := GameSession.new(BALANCING_CONFIG, BalancingFixture.create_seeded_rng(SEED))
	session.score = score
	return session


func _start_game_one_pair_from_end(best_score_before_game: int) -> GameScreen:
	var game: GameScreen = GAME_SCREEN_SCENE.instantiate()
	add_child_autofree(game)
	var session := GameSession.new(BalancingFixture.create_config_always_drawing(1), BalancingFixture.create_seeded_rng(SEED), _create_board_one_pair_from_full())
	session.score = HIGH_SCORE
	game.start_game(session, best_score_before_game)
	return game


func _finish_the_game(game: GameScreen) -> void:
	var board_view: BoardView = game.get_node("%BoardView")
	board_view.column_released.emit(0)
	board_view.pressed_while_locked.emit()
	assert_true(game.get_session().is_game_over, "The fixture game must end on this turn")


func _create_board_one_pair_from_full() -> BoardState:
	return BoardFixture.create_board([
		". 2 3 | 2 3 .",
		"2 3 2 | 3 2 3",
		"3 2 3 | 2 3 2",
		"2 3 2 | 3 2 3",
		"3 2 3 | 2 3 2",
		"2 3 2 | 3 2 3",
	])
