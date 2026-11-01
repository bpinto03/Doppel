extends GutTest

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const GAME_SCREEN_SCENE: PackedScene = preload("res://scenes/game/game_screen.tscn")
const BALANCING_CONFIG: BalancingConfig = preload("res://data/balancing.tres")
const TEST_SAVE_PATH: String = "user://test_coin_wallet_save.cfg"
const MAX_WAIT_SECONDS: float = 5.0
const SEED: int = 1234
const GAME_SCORE: int = 9500
const STARTING_COINS: int = 30

var _save := SaveFixture.new(TEST_SAVE_PATH)


func before_each() -> void:
	_save.use_test_save()
	Settings.is_music_enabled = false
	Settings.is_sound_enabled = false


func after_each() -> void:
	AudioManager.stop_music()
	_save.restore_player_save()
	AudioManager.apply_settings()


func test_empty_wallet_has_no_coins() -> void:
	assert_eq(CoinWallet.get_coins(), 0)


func test_added_coins_add_up() -> void:
	CoinWallet.add_coins(10)
	CoinWallet.add_coins(5)

	assert_eq(CoinWallet.get_coins(), 15)


func test_adding_coins_reports_the_new_total() -> void:
	watch_signals(WalletEvents)

	CoinWallet.add_coins(10)

	assert_signal_emitted_with_parameters(WalletEvents, "coins_changed", [10])


func test_spending_less_than_the_balance_removes_it() -> void:
	CoinWallet.add_coins(STARTING_COINS)

	assert_true(CoinWallet.try_spend(STARTING_COINS - 1))
	assert_eq(CoinWallet.get_coins(), 1)


func test_spending_the_exact_balance_empties_the_wallet() -> void:
	CoinWallet.add_coins(STARTING_COINS)

	assert_true(CoinWallet.try_spend(STARTING_COINS))
	assert_eq(CoinWallet.get_coins(), 0)


func test_spending_more_than_the_balance_changes_nothing() -> void:
	CoinWallet.add_coins(STARTING_COINS)
	watch_signals(WalletEvents)

	assert_false(CoinWallet.try_spend(STARTING_COINS + 1))
	assert_eq(CoinWallet.get_coins(), STARTING_COINS)
	assert_signal_not_emitted(WalletEvents, "coins_changed")


func test_adding_zero_or_negative_coins_is_refused() -> void:
	CoinWallet.add_coins(STARTING_COINS)

	CoinWallet.add_coins(0)
	assert_engine_error("Coins to add must be above 0")
	CoinWallet.add_coins(-5)
	assert_engine_error("Coins to add must be above 0")

	assert_eq(CoinWallet.get_coins(), STARTING_COINS)


func test_damaged_balance_in_the_save_reads_as_zero() -> void:
	for damaged_value: Variant in [-12, 4.5, "40"]:
		SaveManager.set_value(CoinWallet.SECTION, CoinWallet.COINS_KEY, damaged_value)

		assert_eq(CoinWallet.get_coins(), 0, "Saved value: %s" % damaged_value)


func test_balance_survives_a_reload() -> void:
	CoinWallet.add_coins(STARTING_COINS)
	SaveManager.flush()

	SaveManager.load_save()

	assert_eq(CoinWallet.get_coins(), STARTING_COINS)


func test_game_over_pays_the_reward_once_and_erases_the_game() -> void:
	var session: GameSession = _store_coins_and_game_one_pair_from_end()
	var game: GameScreen = _create_game_screen()
	game.start_game(session, 0)
	var board_view: BoardView = game.get_node("%BoardView")

	board_view.column_released.emit(0)
	board_view.pressed_while_locked.emit()
	board_view.column_released.emit(0)
	await wait_process_frames(1)
	SaveManager.load_save()

	var expected_reward: int = CoinReward.calculate_coins(session.score, session.highest_level_reached, BALANCING_CONFIG)
	assert_true(session.is_game_over, "The fixture game must end on this turn")
	assert_gt(expected_reward, 0)
	assert_eq(CoinWallet.get_coins(), STARTING_COINS + expected_reward)
	assert_true(SaveManager.get_section(CurrentGameStore.SECTION).is_empty())
	assert_eq(game.get_coin_reward().coins_earned, expected_reward)
	assert_eq(game.get_coin_reward().total_after, STARTING_COINS + expected_reward)


## A kill before the end of the frame loses both changes: the saved game replays its last turn and pays once.
func test_a_kill_before_the_write_keeps_neither_the_reward_nor_the_erased_game() -> void:
	var session: GameSession = _store_coins_and_game_one_pair_from_end()
	var game: GameScreen = _create_game_screen()
	game.start_game(session, 0)

	game.get_node("%BoardView").column_released.emit(0)
	SaveManager.load_save()

	assert_eq(CoinWallet.get_coins(), STARTING_COINS)
	assert_not_null(CurrentGameStore.load_session(BALANCING_CONFIG))


func test_restart_during_a_game_pays_nothing() -> void:
	var game: GameScreen = _create_game_screen()
	game.start_new_game()
	game.get_node("%BoardView").column_released.emit(0)

	game.start_new_game()

	assert_eq(CoinWallet.get_coins(), 0)
	assert_null(game.get_coin_reward())


func test_play_from_home_over_a_saved_game_pays_nothing() -> void:
	_store_game_in_progress()
	var main: Node = _start_main()

	(main.get_current_screen() as HomeScreen).play_requested.emit()

	assert_eq(CoinWallet.get_coins(), 0)


func test_tutorial_played_to_the_end_pays_nothing() -> void:
	var game: GameScreen = _create_game_screen()
	game.start_tutorial()
	var steps: Array[TutorialStep] = TutorialScenarios.create_steps()

	for step: TutorialStep in steps:
		game.get_node("%BoardView").column_released.emit(step.target_column)
		await wait_for_signal(game.turn_playback_finished, MAX_WAIT_SECONDS)
		game.get_node("%TutorialPanel").next_requested.emit()

	assert_eq(CoinWallet.get_coins(), 0)
	assert_null(game.get_coin_reward())


func test_continued_game_pays_its_reward_on_game_over() -> void:
	var session: GameSession = _create_session_one_pair_from_end()
	CurrentGameStore.store(session, 0)
	SaveManager.flush()
	var main: Node = _start_main()

	(main.get_current_screen() as HomeScreen).continue_requested.emit()
	var game := main.get_current_screen() as GameScreen
	game.get_node("%BoardView").column_released.emit(0)

	var resumed: GameSession = game.get_session()
	assert_true(resumed.is_game_over, "The resumed game must end on this turn")
	assert_eq(CoinWallet.get_coins(), CoinReward.calculate_coins(resumed.score, resumed.highest_level_reached, BALANCING_CONFIG))


func _create_game_screen() -> GameScreen:
	var game: GameScreen = GAME_SCREEN_SCENE.instantiate()
	add_child_autofree(game)
	return game


## As a release build, so the debug starting coins never mix with the rewards checked here.
func _start_main() -> Node:
	var main: Node = MAIN_SCENE.instantiate()
	main.is_debug_build = false
	add_child_autofree(main)
	return main


func _store_game_in_progress() -> void:
	var session := GameSession.new(BALANCING_CONFIG, BalancingFixture.create_seeded_rng(SEED))
	session.play_column(0)
	session.score = GAME_SCORE
	CurrentGameStore.store(session, 0)


func _store_coins_and_game_one_pair_from_end() -> GameSession:
	CoinWallet.add_coins(STARTING_COINS)
	var session: GameSession = _create_session_one_pair_from_end()
	CurrentGameStore.store(session, 0)
	SaveManager.flush()
	return session


func _create_session_one_pair_from_end() -> GameSession:
	var session := GameSession.new(BALANCING_CONFIG, BalancingFixture.create_seeded_rng(SEED), _create_board_one_pair_from_full())
	session.score = GAME_SCORE
	return session


func _create_board_one_pair_from_full() -> BoardState:
	return BoardFixture.create_board([
		". 2 3 | 2 3 .",
		"2 3 2 | 3 2 3",
		"3 2 3 | 2 3 2",
		"2 3 2 | 3 2 3",
		"3 2 3 | 2 3 2",
		"2 3 2 | 3 2 3",
	])
