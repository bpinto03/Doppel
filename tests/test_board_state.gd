extends GutTest


func test_drop_tile_lands_at_bottom_of_empty_column() -> void:
	var board := BoardState.new(3, 6)

	var landing_cell: Vector2i = board.drop_tile(1, 2)

	assert_eq(landing_cell, Vector2i(1, 0))
	assert_eq(board.get_level(landing_cell), 2)


func test_drop_tile_stacks_on_top_of_existing_tiles() -> void:
	var board: BoardState = BoardFixture.create_board([
		". . . | . . .",
		"3 . . | . . .",
		"1 . . | . . .",
	])

	assert_eq(board.drop_tile(0, 2), Vector2i(0, 2))


func test_mirror_column_reflects_across_axis() -> void:
	var board := BoardState.new(3, 6)

	assert_eq(board.get_mirror_column(0), 5)
	assert_eq(board.get_mirror_column(1), 4)
	assert_eq(board.get_mirror_column(2), 3)


func test_columns_next_to_axis_are_orthogonal_neighbors() -> void:
	var board := BoardState.new(3, 6)

	assert_has(board.get_orthogonal_neighbors(Vector2i(2, 0)), Vector2i(3, 0))


func test_column_is_full_when_every_row_holds_a_tile() -> void:
	var board: BoardState = BoardFixture.create_board([
		"1 . . | . . .",
		"2 . . | . . .",
	])

	assert_true(board.is_column_full(0))
	assert_false(board.is_column_full(1))


func test_gravity_drops_floating_tiles_and_reports_their_new_cells() -> void:
	var board: BoardState = BoardFixture.create_board([
		"2 . . | . . .",
		"1 . . | . . 4",
		". . . | . . .",
	])

	var fallen_cells: Array[Vector2i] = board.apply_gravity()

	assert_eq(BoardFixture.describe_board(board), [
		". . . | . . .",
		"2 . . | . . .",
		"1 . . | . . 4",
	])
	assert_eq_deep(fallen_cells, [Vector2i(0, 0), Vector2i(0, 1), Vector2i(5, 0)])


func test_gravity_does_not_move_settled_tiles() -> void:
	var board: BoardState = BoardFixture.create_board([
		". . . | . . .",
		"1 2 3 | 3 2 1",
	])

	assert_true(board.apply_gravity().is_empty())
