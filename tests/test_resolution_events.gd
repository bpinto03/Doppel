extends GutTest

const SEED: int = 1234
const EMPTY_ROW: String = ". . . | . . ."


func test_simple_drop_records_only_the_placement() -> void:
	var session: GameSession = _create_session_always_drawing(1, null)

	var result: ChainResult = session.play_column(0)

	assert_eq(result.events.size(), 1)
	var placed_event := result.events[0] as TilesPlacedEvent
	assert_not_null(placed_event)
	assert_eq(placed_event.tile_cell, Vector2i(0, 0))
	assert_eq(placed_event.tile_level, 1)
	assert_eq(placed_event.reflection_cell, Vector2i(5, 0))
	assert_eq(placed_event.reflection_level, 1)
	assert_false(placed_event.is_reflection_distorted)


func test_merge_records_placement_then_merge_then_fall() -> void:
	var result: ChainResult = _play_simple_merge().play_result

	assert_eq(result.events.size(), 3)
	assert_true(result.events[0] is TilesPlacedEvent)
	var merged_event := result.events[1] as GroupMergedEvent
	assert_eq(merged_event.chain_link, 1)
	assert_eq(merged_event.chain_multiplier, 1.0)
	assert_eq(merged_event.group_level, 1)
	assert_eq(merged_event.result_cell, Vector2i(0, 1))
	assert_eq(merged_event.result_level, 2)
	assert_eq(merged_event.points_earned, 4)
	assert_false(merged_event.is_crossing_axis)
	var fell_event := result.events[2] as TilesFellEvent
	assert_eq(fell_event.chain_link, 1)
	assert_eq(fell_event.falls.size(), 1)
	assert_eq(fell_event.falls[0].from_cell, Vector2i(0, 1))
	assert_eq(fell_event.falls[0].to_cell, Vector2i(0, 0))


func test_three_link_chain_records_each_link_with_its_multiplier() -> void:
	var result: ChainResult = _play_three_link_chain().play_result

	var event_kinds: Array[String] = []
	for event: ResolutionEvent in result.events:
		event_kinds.append(_describe_event_kind(event))
	assert_eq(event_kinds, ["placed", "merged 1", "fell 1", "merged 2", "fell 2", "merged 3"])
	var last_merge := result.events[5] as GroupMergedEvent
	assert_eq(last_merge.chain_multiplier, 3.0)
	assert_eq(last_merge.result_level, 4)
	assert_eq(last_merge.points_earned, 48)


func test_merge_across_axis_lands_on_left_side_and_right_column_falls() -> void:
	var result: ChainResult = _play_merge_across_axis().play_result

	assert_eq(result.events.size(), 3)
	var merged_event := result.events[1] as GroupMergedEvent
	assert_true(merged_event.is_crossing_axis)
	assert_eq(merged_event.group_cells.size(), 2)
	assert_has(merged_event.group_cells, Vector2i(2, 0))
	assert_has(merged_event.group_cells, Vector2i(3, 0))
	assert_eq(merged_event.result_cell, Vector2i(2, 0))
	assert_eq(merged_event.result_level, 3)
	var fell_event := result.events[2] as TilesFellEvent
	for fall: TileFall in fell_event.falls:
		assert_eq(fall.to_cell.x, 3)
	assert_eq(fell_event.falls.size(), 2)


func test_replaying_events_rebuilds_the_final_board() -> void:
	for played_turn: PlayedTurn in [_play_simple_merge(), _play_three_link_chain(), _play_merge_across_axis()]:
		var replayed_board: BoardState = played_turn.board_before
		for event: ResolutionEvent in played_turn.play_result.events:
			event.apply_to(replayed_board)

		assert_eq(BoardFixture.describe_board(replayed_board), BoardFixture.describe_board(played_turn.session.board))


func test_event_points_add_up_to_the_score_gained() -> void:
	for played_turn: PlayedTurn in [_play_simple_merge(), _play_three_link_chain(), _play_merge_across_axis()]:
		var event_points: int = 0
		for event: ResolutionEvent in played_turn.play_result.events:
			if event is GroupMergedEvent:
				event_points += (event as GroupMergedEvent).points_earned

		assert_eq(event_points, played_turn.session.score - played_turn.score_before)
		assert_gt(event_points, 0)


func _play_simple_merge() -> PlayedTurn:
	return _play_turn(1, 0, [
		"1 . . | . . .",
	])


## Link 1 merges the placed 1, link 2 the resulting 2 with its neighbor, link 3 the 3 that fell.
func _play_three_link_chain() -> PlayedTurn:
	return _play_turn(1, 0, [
		". 3 . | . . .",
		"1 2 . | . . .",
	])


## The 1 above the waiting 2 keeps the reflection out of the merge.
func _play_merge_across_axis() -> PlayedTurn:
	return _play_turn(2, 2, [
		". . . | 1 . .",
		". . . | 2 . .",
	])


func _play_turn(tile_level: int, column: int, rows_from_top: Array[String]) -> PlayedTurn:
	var played_turn := PlayedTurn.new()
	played_turn.session = _create_session_always_drawing(tile_level, BoardFixture.create_board(_pad_to_full_height(rows_from_top)))
	played_turn.board_before = played_turn.session.board.duplicate_board()
	played_turn.score_before = played_turn.session.score
	played_turn.play_result = played_turn.session.play_column(column)
	return played_turn


func _pad_to_full_height(rows_from_top: Array[String]) -> Array[String]:
	var padded_rows: Array[String] = []
	for i: int in BalancingFixture.create_config().row_count - rows_from_top.size():
		padded_rows.append(EMPTY_ROW)
	padded_rows.append_array(rows_from_top)
	return padded_rows


func _create_session_always_drawing(level: int, initial_board: BoardState) -> GameSession:
	return GameSession.new(BalancingFixture.create_config_always_drawing(level), BalancingFixture.create_seeded_rng(SEED), initial_board)


func _describe_event_kind(event: ResolutionEvent) -> String:
	if event is TilesPlacedEvent:
		return "placed"
	if event is GroupMergedEvent:
		return "merged %d" % (event as GroupMergedEvent).chain_link
	return "fell %d" % (event as TilesFellEvent).chain_link


class PlayedTurn:
	var session: GameSession
	var board_before: BoardState
	var score_before: int
	var play_result: ChainResult
