extends GutTest

const GAME_SCREEN_SCENE: PackedScene = preload("res://scenes/game/game_screen.tscn")
const BALANCING_CONFIG: BalancingConfig = preload("res://data/balancing.tres")
const TEST_SAVE_PATH: String = "user://test_game_over_save.cfg"
const SEED: int = 1234
const PREVIOUS_BEST: int = 100
const HIGH_SCORE: int = 500
const STARTING_COINS: int = 30
const EFFECTS_CONFIG: GameOverEffectsConfig = preload("res://data/game_over_effects.tres")

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
	assert_eq((panel.get_node("%ScoreValue") as Label).text, str(game.get_session().score))
	assert_eq((panel.get_node("%BestValue") as Label).text, str(RecordBook.get_best_score()))
	var highest_tile_value: int = MergeScoring.calculate_tile_value(game.get_session().highest_level_reached)
	assert_eq((panel.get_node("%MaxTileValue") as Label).text, str(highest_tile_value))
	assert_eq(game.get_navigation_state(), ScreenNavigation.GameState.GAME_OVER)


func test_game_over_panel_shows_the_coins_earned_and_the_balance() -> void:
	CoinWallet.add_coins(STARTING_COINS)
	var game: GameScreen = _start_game_one_pair_from_end(PREVIOUS_BEST)

	_finish_the_game(game)

	var panel: GameOverPanel = game.get_node("%GameOverPanel")
	var reward: CoinRewardResult = game.get_coin_reward()
	assert_true((panel.get_node("%RewardSlot") as Control).visible)
	assert_eq(panel.get_coin_gain_text(), "+%d" % reward.coins_earned)
	assert_eq((panel.get_node("%CoinCounter") as CoinCounter).get_shown_text(), str(STARTING_COINS + reward.coins_earned))


func test_coins_earned_pop_only_with_screen_shake_on() -> void:
	for is_shake_enabled: bool in [true, false]:
		Settings.is_screen_shake_enabled = is_shake_enabled
		var game: GameScreen = _start_game_one_pair_from_end(PREVIOUS_BEST)

		_finish_the_game(game)

		var panel: GameOverPanel = game.get_node("%GameOverPanel")
		assert_eq(panel.is_coin_gain_popping(), is_shake_enabled, "screen shake: %s" % is_shake_enabled)


func test_a_game_over_without_reward_hides_the_reward_slot() -> void:
	var game: GameScreen = _start_game_one_pair_from_end(PREVIOUS_BEST)
	var panel: GameOverPanel = game.get_node("%GameOverPanel")

	panel.show_summary(GameOverSummary.new(_create_session_with_score(HIGH_SCORE), PREVIOUS_BEST, HIGH_SCORE), null)

	assert_false((panel.get_node("%RewardSlot") as Control).visible)


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


func test_every_game_over_shows_the_crown_its_halo_and_confetti() -> void:
	for best_score_before_game: int in [0, PREVIOUS_BEST, HIGH_SCORE * 2]:
		var game: GameScreen = _start_game_one_pair_from_end(best_score_before_game)
		_finish_the_game(game)
		await wait_seconds(EFFECTS_CONFIG.appear_duration)
		await wait_process_frames(1)

		var panel: GameOverPanel = game.get_node("%GameOverPanel")
		var context: String = "record before: %d" % best_score_before_game
		assert_true((panel.get_node("%Crown") as Control).is_visible_in_tree(), context)
		assert_not_null((panel.get_node("%Crown") as TextureRect).texture, context)
		assert_true((panel.get_node("%Halo") as Control).is_visible_in_tree(), context)
		assert_gt((panel.get_node("%Halo") as CrownHalo).color.a, 0.0, context)
		assert_true(panel.is_halo_animated(), context)
		assert_true(_get_confetti(game).is_showing_confetti(), context)
		var panel_rect: Rect2 = (panel.get_node("%Panel") as Control).get_global_rect()
		assert_almost_eq(_get_confetti(game).get_line_origin(), Vector2(panel_rect.get_center().x, panel_rect.position.y), Vector2.ONE, "Confetti leave from the top edge of the panel, %s" % context)


func test_the_record_burst_needs_a_beaten_record_above_zero() -> void:
	var expected_amounts: Dictionary[int, int] = {
		0: EFFECTS_CONFIG.confetti_amount,
		PREVIOUS_BEST: EFFECTS_CONFIG.record_confetti_amount,
		HIGH_SCORE * 2: EFFECTS_CONFIG.confetti_amount,
	}
	for best_score_before_game: int in expected_amounts:
		var game: GameScreen = _start_game_one_pair_from_end(best_score_before_game)

		_finish_the_game(game)
		await wait_process_frames(1)

		assert_eq(_get_confetti(game).get_amount(), expected_amounts[best_score_before_game], "record before: %d" % best_score_before_game)


func test_play_again_removes_every_confetti_piece_and_stops_the_halo() -> void:
	var game: GameScreen = _start_game_one_pair_from_end(PREVIOUS_BEST)
	_finish_the_game(game)
	await wait_process_frames(2)

	(game.get_node("%GameOverPanel").get_node("%ReplayButton") as Button).pressed.emit()

	assert_false(_get_confetti(game).is_showing_confetti())
	assert_false((_get_confetti(game).get_child(0) as CanvasItem).is_visible_in_tree(), "No piece stays drawn over the new game")
	assert_false((game.get_node("%GameOverPanel") as GameOverPanel).is_halo_animated(), "The halo stops with the panel")


func test_record_before_the_game_survives_with_the_saved_game() -> void:
	CurrentGameStore.store(_create_session_with_score(HIGH_SCORE), PREVIOUS_BEST)
	SaveManager.flush()
	SaveManager.load_save()

	assert_eq(CurrentGameStore.load_best_score_before_game(), PREVIOUS_BEST)


func test_saved_game_without_the_record_before_it_uses_the_current_record() -> void:
	SaveManager.set_value(RecordBook.SECTION, RecordBook.BEST_SCORE_KEY, PREVIOUS_BEST)

	assert_eq(CurrentGameStore.load_best_score_before_game(), PREVIOUS_BEST)


func _get_confetti(game: GameScreen) -> ConfettiBurst:
	return game.get_node("%GameOverPanel").get_node("Confetti")


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
