extends GutTest

var _resolver: MergeResolver


func before_each() -> void:
	_resolver = MergeResolver.new(BalancingFixture.create_config())


func test_vertical_pair_merges_into_one_higher_tile() -> void:
	var board: BoardState = BoardFixture.create_board([
		"1 . . | . . .",
		"1 . . | . . .",
	])

	var result: ChainResult = _resolver.resolve_chain(board, [Vector2i(0, 1)])

	assert_eq(BoardFixture.describe_board(board), [
		". . . | . . .",
		"2 . . | . . .",
	])
	assert_eq(result.chain_length, 1)
	assert_eq(result.highest_level_created, 2)


func test_result_lands_on_placed_tile() -> void:
	var board: BoardState = BoardFixture.create_board([
		"1 1 . | . . .",
	])

	_resolver.resolve_chain(board, [Vector2i(0, 0)])

	assert_eq(BoardFixture.describe_board(board), ["2 . . | . . ."])


func test_result_lands_on_lowest_cell_closest_to_axis_without_placed_tile() -> void:
	var board: BoardState = BoardFixture.create_board([
		"1 1 . | . . .",
	])

	_resolver.resolve_chain(board, [])

	assert_eq(BoardFixture.describe_board(board), [". 2 . | . . ."])


func test_group_of_three_merges_into_a_single_tile() -> void:
	var board: BoardState = BoardFixture.create_board([
		". 1 . | . . .",
		"1 1 . | . . .",
	])

	var result: ChainResult = _resolver.resolve_chain(board, [Vector2i(1, 1)])

	assert_eq(BoardFixture.describe_board(board), [
		". . . | . . .",
		". 2 . | . . .",
	])
	assert_eq(result.chain_length, 1)


func test_separate_groups_merge_in_the_same_chain_link() -> void:
	var board: BoardState = BoardFixture.create_board([
		"1 1 . | . 2 2",
	])

	var result: ChainResult = _resolver.resolve_chain(board, [])

	assert_eq(BoardFixture.describe_board(board), [". 2 . | . 3 ."])
	assert_eq(result.chain_length, 1)
	assert_eq(result.points_earned, 4 + 8)


func test_chain_of_two() -> void:
	var board: BoardState = BoardFixture.create_board([
		"1 . . | . . .",
		"1 2 . | . . .",
	])

	var result: ChainResult = _resolver.resolve_chain(board, [Vector2i(0, 1)])

	assert_eq(BoardFixture.describe_board(board), [
		". . . | . . .",
		"3 . . | . . .",
	])
	assert_eq(result.chain_length, 2)
	assert_eq(result.points_earned, 4 * 1 + 8 * 2)


func test_chain_of_three() -> void:
	var board: BoardState = BoardFixture.create_board([
		"1 . . | . . .",
		"1 2 . | . . .",
		"3 5 . | . . .",
	])

	var result: ChainResult = _resolver.resolve_chain(board, [Vector2i(0, 2)])

	assert_eq(BoardFixture.describe_board(board), [
		". . . | . . .",
		". . . | . . .",
		"4 5 . | . . .",
	])
	assert_eq(result.chain_length, 3)
	assert_eq(result.points_earned, 4 * 1 + 8 * 2 + 16 * 3)
	assert_eq(result.highest_level_created, 4)


func test_merge_across_axis_keeps_result_on_left_side() -> void:
	var board: BoardState = BoardFixture.create_board([
		". . 2 | 2 . .",
	])

	_resolver.resolve_chain(board, [Vector2i(2, 0), Vector2i(3, 0)])

	assert_eq(BoardFixture.describe_board(board), [". . 3 | . . ."])


func test_axis_rule_takes_priority_over_placed_cell() -> void:
	var board: BoardState = BoardFixture.create_board([
		". . . | 2 . .",
		". . 2 | 2 . .",
	])

	_resolver.resolve_chain(board, [Vector2i(3, 1)])

	assert_eq(BoardFixture.describe_board(board), [
		". . . | . . .",
		". . 3 | . . .",
	])


func test_merge_across_axis_leaves_board_asymmetric_with_independent_gravity() -> void:
	var board: BoardState = BoardFixture.create_board([
		". . . | 4 . .",
		". . 2 | 2 . 1",
	])

	_resolver.resolve_chain(board, [Vector2i(2, 0)])

	assert_eq(BoardFixture.describe_board(board), [
		". . . | . . .",
		". . 3 | 4 . 1",
	])


func test_max_level_tiles_do_not_merge() -> void:
	var board: BoardState = BoardFixture.create_board([
		"12 12 . | . . .",
	])

	var result: ChainResult = _resolver.resolve_chain(board, [Vector2i(1, 0)])

	assert_eq(result.chain_length, 0)
	assert_eq(BoardFixture.describe_board(board), ["12 12 . | . . ."])


func test_diagonal_tiles_do_not_merge() -> void:
	var board: BoardState = BoardFixture.create_board([
		"1 . . | . . .",
		"2 1 . | . . .",
	])

	assert_eq(_resolver.resolve_chain(board, []).chain_length, 0)
