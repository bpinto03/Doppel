extends GutTest


func test_tile_lands_at_bottom_of_empty_column() -> void:
	var board := BoardState.new(3, 6)

	assert_eq(board.get_landing_cell(1), Vector2i(1, 0))


func test_tile_lands_on_top_of_existing_tiles() -> void:
	var board: BoardState = BoardFixture.create_board([
		". . . | . . .",
		"3 . . | . . .",
		"1 . . | . . .",
	])

	assert_eq(board.get_landing_cell(0), Vector2i(0, 2))


func test_mirror_column_reflects_across_axis() -> void:
	var board := BoardState.new(3, 6)

	assert_eq(board.get_mirror_column(0), 5)
	assert_eq(board.get_mirror_column(1), 4)
	assert_eq(board.get_mirror_column(2), 3)


func test_columns_next_to_axis_are_orthogonal_neighbors() -> void:
	var board := BoardState.new(3, 6)

	assert_has(board.get_orthogonal_neighbors(Vector2i(2, 0)), Vector2i(3, 0))


func test_highest_level_is_the_highest_tile_on_either_side() -> void:
	var board: BoardState = BoardFixture.create_board([
		"1 . . | . . .",
		"3 . . | 2 . 5",
	])

	assert_eq(board.get_highest_level(), 5)


func test_highest_level_of_empty_board_is_empty_cell() -> void:
	assert_eq(BoardState.new(3, 6).get_highest_level(), BoardState.EMPTY_CELL)


func test_column_is_full_when_every_row_holds_a_tile() -> void:
	var board: BoardState = BoardFixture.create_board([
		"1 . . | . . .",
		"2 . . | . . .",
	])

	assert_true(board.is_column_full(0))
	assert_false(board.is_column_full(1))


func test_gravity_drops_floating_tiles_and_reports_each_fall() -> void:
	var board: BoardState = BoardFixture.create_board([
		"2 . . | . . .",
		"1 . . | . . 4",
		". . . | . . .",
	])

	var falls: Array[TileFall] = board.apply_gravity()

	assert_eq(BoardFixture.describe_board(board), [
		". . . | . . .",
		"2 . . | . . .",
		"1 . . | . . 4",
	])
	assert_eq(falls.size(), 3)
	_assert_fall(falls[0], Vector2i(0, 1), Vector2i(0, 0), 1)
	_assert_fall(falls[1], Vector2i(0, 2), Vector2i(0, 1), 2)
	_assert_fall(falls[2], Vector2i(5, 1), Vector2i(5, 0), 4)


func test_gravity_does_not_move_settled_tiles() -> void:
	var board: BoardState = BoardFixture.create_board([
		". . . | . . .",
		"1 2 3 | 3 2 1",
	])

	assert_true(board.apply_gravity().is_empty())


func test_duplicated_board_is_independent_of_the_original() -> void:
	var board: BoardState = BoardFixture.create_board([
		"1 . . | . . 2",
	])

	var copy: BoardState = board.duplicate_board()
	copy.set_level(Vector2i(0, 0), 5)

	assert_eq(board.get_level(Vector2i(0, 0)), 1)
	assert_eq(copy.get_level(Vector2i(5, 0)), 2)


func _assert_fall(fall: TileFall, from_cell: Vector2i, to_cell: Vector2i, level: int) -> void:
	assert_eq(fall.from_cell, from_cell)
	assert_eq(fall.to_cell, to_cell)
	assert_eq(fall.level, level)
