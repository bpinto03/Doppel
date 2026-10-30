extends GutTest

const SEED: int = 1234
const TURN_COUNT: int = 30

var _config: BalancingConfig


func before_each() -> void:
	_config = BalancingFixture.create_config()
	_config.is_distorted_reflection_enabled = true


func test_every_strategy_plays_only_playable_columns_until_the_game_ends() -> void:
	for strategy: PlayStrategy in _create_strategies():
		var session := GameSession.new(_config, BalancingFixture.create_seeded_rng(SEED))
		var tie_breaker: RandomNumberGenerator = BalancingFixture.create_seeded_rng(SEED)
		while not session.is_game_over:
			var column: int = strategy.choose_column(session, tie_breaker)
			assert_true(session.can_play_column(column), "%s chose column %d" % [strategy.get_strategy_name(), column])
			session.play_column(column)


func test_every_strategy_avoids_a_full_column() -> void:
	var board: BoardState = BoardFixture.create_board([
		"1 . . | . . 2",
		"2 . . | . . 1",
		"1 . . | . . 2",
		"2 . . | . . 1",
		"1 . . | . . 2",
		"2 . . | . . 1",
	])

	for strategy: PlayStrategy in _create_strategies():
		var session := GameSession.new(_config, BalancingFixture.create_seeded_rng(SEED), board.duplicate_board())
		for attempt: int in TURN_COUNT:
			assert_ne(strategy.choose_column(session, BalancingFixture.create_seeded_rng(attempt)), 0, strategy.get_strategy_name())


func test_evaluating_moves_leaves_the_game_and_its_generator_untouched() -> void:
	var session := GameSession.new(_config, BalancingFixture.create_seeded_rng(SEED))
	session.play_column(0)
	var data_before: Dictionary[String, Variant] = session.to_data()
	var evaluator := MoveEvaluator.new(_config)

	for column: int in PlayStrategy.find_playable_columns(session):
		evaluator.evaluate(session, column)
	for strategy: PlayStrategy in _create_strategies():
		strategy.choose_column(session, BalancingFixture.create_seeded_rng(SEED))

	assert_eq(session.to_data(), data_before)


func test_evaluation_matches_the_real_move() -> void:
	var session := GameSession.new(_config, BalancingFixture.create_seeded_rng(SEED))
	session.play_column(1)

	var outcome: MoveOutcome = MoveEvaluator.new(_config).evaluate(session, 2)
	var chain_result: ChainResult = session.play_column(2)

	assert_eq(BoardFixture.describe_board(outcome.board_after), BoardFixture.describe_board(session.board))
	assert_eq(outcome.points, chain_result.points_earned)
	assert_eq(outcome.chain_length, chain_result.chain_length)


## Only column 1 lands the tile on a 2; the other landing cells touch the 3 or nothing.
func test_greedy_takes_the_move_that_scores() -> void:
	var always_two: BalancingConfig = BalancingFixture.create_config_always_drawing(2)
	always_two.is_cross_axis_merge_enabled = false
	var board: BoardState = BoardFixture.create_board([
		". . . | . . .",
		". . . | . . .",
		". . . | . . .",
		". . . | . . .",
		". 2 . | . . .",
		". 3 . | . . .",
	])
	var session := GameSession.new(always_two, BalancingFixture.create_seeded_rng(SEED), board)

	assert_eq(GreedyStrategy.new(always_two).choose_column(session, BalancingFixture.create_seeded_rng(SEED)), 1)


## G1 and D3 hold a 3: a 3 merges on both sides of columns G1 and G2; in G3, the tile and its reflection touch across the axis.
func test_next_tile_merges_count_the_tile_and_the_reflection_side() -> void:
	var heuristic := HeuristicStrategy.new(_config)
	var board: BoardState = BoardFixture.create_board([
		". . . | . . .",
		". . . | . . .",
		". . . | . . .",
		". . . | . . .",
		". . . | . . .",
		"3 . . | . . 3",
	])

	assert_eq(heuristic.count_next_tile_merges(board, 3), 6)
	assert_eq(heuristic.count_next_tile_merges(board, 2), 2)
	_config.is_cross_axis_merge_enabled = false
	assert_eq(heuristic.count_next_tile_merges(board, 3), 4)
	assert_eq(heuristic.count_next_tile_merges(board, 2), 0)


func test_nearly_full_pairs_count_the_tallest_side() -> void:
	var heuristic := HeuristicStrategy.new(_config)
	var board: BoardState = BoardFixture.create_board([
		". . . | . . .",
		"1 . . | . . .",
		"2 . . | . . .",
		"1 . . | . . .",
		"2 . . | . . .",
		"1 . . | . . 2",
	])

	assert_eq(heuristic.count_nearly_full_pairs(board), 1)


func test_ties_are_broken_the_same_way_with_the_same_seed() -> void:
	var columns: Array[int] = [0, 1, 2]
	var scores: Array[float] = [5.0, 5.0, 5.0]

	assert_eq(
		PlayStrategy.pick_best_column(columns, scores, BalancingFixture.create_seeded_rng(SEED)),
		PlayStrategy.pick_best_column(columns, scores, BalancingFixture.create_seeded_rng(SEED))
	)


func _create_strategies() -> Array[PlayStrategy]:
	return [RandomStrategy.new(), GreedyStrategy.new(_config), HeuristicStrategy.new(_config)]
