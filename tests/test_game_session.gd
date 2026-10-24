extends GutTest

const SEED: int = 1234


func test_placed_tile_is_reflected_in_mirror_column() -> void:
	var session: GameSession = _create_session_always_drawing(2)

	session.play_column(0)

	assert_eq(BoardFixture.describe_board(session.board)[5], "2 . . | . . 2")
	assert_eq(session.placement_count, 1)


func test_playing_next_to_axis_merges_tile_with_its_reflection() -> void:
	var session: GameSession = _create_session_always_drawing(2)

	var result: ChainResult = session.play_column(2)

	assert_eq(BoardFixture.describe_board(session.board)[5], ". . 3 | . . .")
	assert_eq(result.points_earned, 8)
	assert_eq(session.score, 8)
	assert_eq(session.highest_level_reached, 3)


func test_score_accumulates_over_turns() -> void:
	var session: GameSession = _create_session_always_drawing(2)

	session.play_column(2)
	session.play_column(0)

	assert_eq(session.score, 8)


func test_preview_tile_becomes_current_after_a_turn() -> void:
	var session := GameSession.new(BalancingFixture.create_config(), BalancingFixture.create_seeded_rng(SEED))
	var previewed_level: int = session.tile_generator.next_level

	session.play_column(0)

	assert_eq(session.tile_generator.current_level, previewed_level)


func test_reflection_is_distorted_every_configured_placement() -> void:
	var config: BalancingConfig = BalancingFixture.create_config()
	config.is_distorted_reflection_enabled = true
	var session: GameSession = _create_session_always_drawing(2, config)
	session.placement_count = config.distorted_reflection_period - 1

	session.play_column(0)

	assert_eq(BoardFixture.describe_board(session.board)[5], "2 . . | . . 3")
	assert_false(session.is_next_reflection_distorted())


func test_reflection_is_not_distorted_between_periods() -> void:
	var config: BalancingConfig = BalancingFixture.create_config()
	config.is_distorted_reflection_enabled = true
	var session: GameSession = _create_session_always_drawing(2, config)

	for placement: int in config.distorted_reflection_period - 1:
		assert_false(session.is_next_reflection_distorted())
		session.placement_count += 1
	assert_true(session.is_next_reflection_distorted())


func test_reflection_is_never_distorted_when_option_is_disabled() -> void:
	var config: BalancingConfig = BalancingFixture.create_config()
	var session: GameSession = _create_session_always_drawing(2, config)
	session.placement_count = config.distorted_reflection_period - 1

	assert_false(session.is_next_reflection_distorted())
	assert_eq(session.get_next_reflection_level(), 2)


func test_distorted_reflection_is_capped_at_max_level() -> void:
	var config: BalancingConfig = BalancingFixture.create_config()
	config.is_distorted_reflection_enabled = true
	var session: GameSession = _create_session_always_drawing(config.max_tile_level, config)
	session.placement_count = config.distorted_reflection_period - 1

	assert_eq(session.get_next_reflection_level(), config.max_tile_level)


func test_column_cannot_be_played_when_its_mirror_is_full() -> void:
	var session: GameSession = _create_session_always_drawing(1)
	session.board = BoardFixture.create_board([
		". . . | . . 3",
		". . . | . . 2",
	])

	assert_false(session.can_play_column(0))
	assert_true(session.can_play_column(1))


func test_full_column_cannot_be_played_even_if_tile_would_merge() -> void:
	var session: GameSession = _create_session_always_drawing(1)
	session.board = BoardFixture.create_board([
		"1 . . | . . .",
		"2 . . | . . .",
	])

	assert_false(session.can_play_column(0))


func test_right_columns_cannot_be_played() -> void:
	var session: GameSession = _create_session_always_drawing(1)

	assert_false(session.can_play_column(3))


func test_game_is_over_when_no_left_column_and_mirror_have_space() -> void:
	var session: GameSession = _create_session_always_drawing(1)
	session.board = BoardFixture.create_board([
		". 5 6 | 7 8 .",
		"3 4 5 | 6 7 9",
	])

	session.play_column(0)

	assert_true(session.is_game_over)
	for column: int in session.board.column_count_per_side:
		assert_false(session.can_play_column(column))


func test_game_continues_while_a_column_pair_has_space() -> void:
	var session: GameSession = _create_session_always_drawing(1)
	session.board = BoardFixture.create_board([
		". . 6 | 7 . .",
		"3 4 5 | 6 7 9",
	])

	session.play_column(0)

	assert_false(session.is_game_over)


func test_same_seed_replays_the_same_game() -> void:
	var first_session := GameSession.new(BalancingFixture.create_config(), BalancingFixture.create_seeded_rng(SEED))
	var second_session := GameSession.new(BalancingFixture.create_config(), BalancingFixture.create_seeded_rng(SEED))

	_play_first_available_column_until_game_over(first_session)
	_play_first_available_column_until_game_over(second_session)

	assert_eq(first_session.score, second_session.score)
	assert_eq(first_session.placement_count, second_session.placement_count)
	assert_eq(BoardFixture.describe_board(first_session.board), BoardFixture.describe_board(second_session.board))


func _create_session_always_drawing(level: int, config: BalancingConfig = BalancingFixture.create_config()) -> GameSession:
	config.spawn_weight_tiers = [BalancingFixture.create_tier(0, {level: 1.0})]
	return GameSession.new(config, BalancingFixture.create_seeded_rng(SEED))


func _play_first_available_column_until_game_over(session: GameSession) -> void:
	while not session.is_game_over:
		for column: int in session.board.column_count_per_side:
			if session.can_play_column(column):
				session.play_column(column)
				break
