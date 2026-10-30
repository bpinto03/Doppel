extends GutTest

const SEED: int = 1234
const TURNS_BEFORE_SAVE: int = 7
const TURNS_AFTER_SAVE: int = 12
const DISTORTED_REFLECTION_PERIOD: int = 3

var _config: BalancingConfig


func before_each() -> void:
	_config = BalancingFixture.create_config()
	_config.is_distorted_reflection_enabled = true
	_config.distorted_reflection_period = DISTORTED_REFLECTION_PERIOD


func test_restored_session_matches_the_saved_one() -> void:
	var session: GameSession = _create_playing_session()
	_play_turns(session, TURNS_BEFORE_SAVE)

	var restored: GameSession = GameSession.create_from_data(_config, session.to_data())

	assert_not_null(restored)
	assert_eq(restored.to_data(), session.to_data())
	assert_eq(BoardFixture.describe_board(restored.board), BoardFixture.describe_board(session.board))
	assert_eq(restored.get_next_reflection_level(), session.get_next_reflection_level())


## Includes distorted reflections, so the placement count must survive the save too.
func test_restored_session_plays_the_same_tiles_as_the_uninterrupted_one() -> void:
	var uninterrupted: GameSession = _create_playing_session()
	_play_turns(uninterrupted, TURNS_BEFORE_SAVE)
	var restored: GameSession = GameSession.create_from_data(_config, uninterrupted.to_data())
	var distorted_turn_count: int = 0

	for turn: int in TURNS_AFTER_SAVE:
		if uninterrupted.is_game_over:
			break
		assert_eq(_describe_next_turn(restored), _describe_next_turn(uninterrupted), "Turn %d after the save" % turn)
		if uninterrupted.is_next_reflection_distorted():
			distorted_turn_count += 1
		var column: int = _find_first_playable_column(uninterrupted)
		uninterrupted.play_column(column)
		restored.play_column(column)
		assert_eq(restored.to_data(), uninterrupted.to_data(), "State after turn %d" % turn)

	assert_gt(distorted_turn_count, 0, "The sequence must cover distorted reflections")


func test_data_holds_only_plain_values() -> void:
	var data: Dictionary[String, Variant] = _create_playing_session().to_data()

	for key: String in data:
		assert_true(data[key] is int or data[key] is PackedInt32Array, "Key %s" % key)


func test_finished_game_is_not_restored() -> void:
	var always_one: BalancingConfig = BalancingFixture.create_config_always_drawing(1)
	var session := GameSession.new(always_one, BalancingFixture.create_seeded_rng(SEED), _create_board_one_pair_from_full())
	session.play_column(0)

	assert_true(session.is_game_over)
	assert_null(GameSession.create_from_data(always_one, session.to_data()))


func test_other_rules_version_is_not_restored() -> void:
	var session: GameSession = _create_playing_session()
	var newer_rules: BalancingConfig = _config.duplicate()
	newer_rules.rules_version += 1

	assert_null(GameSession.create_from_data(newer_rules, session.to_data()))


func test_other_board_size_is_not_restored() -> void:
	var session: GameSession = _create_playing_session()
	var larger_board: BalancingConfig = _config.duplicate()
	larger_board.row_count += 1

	assert_null(GameSession.create_from_data(larger_board, session.to_data()))


func test_invalid_values_are_not_restored() -> void:
	var session: GameSession = _create_playing_session()
	_play_turns(session, TURNS_BEFORE_SAVE)
	var config: BalancingConfig = _config
	var invalid_changes: Dictionary[String, Variant] = {
		"level above the maximum": {GameSession.BOARD_LEVELS_KEY: _with_first_level(session, config.max_tile_level + 1)},
		"negative level": {GameSession.BOARD_LEVELS_KEY: _with_first_level(session, -1)},
		"floating tile": {GameSession.BOARD_LEVELS_KEY: _with_floating_tile(session)},
		"missing cells": {GameSession.BOARD_LEVELS_KEY: PackedInt32Array([1, 2])},
		"empty current tile": {TileGenerator.CURRENT_LEVEL_KEY: BoardState.EMPTY_CELL},
		"next tile above the maximum": {TileGenerator.NEXT_LEVEL_KEY: config.max_tile_level + 1},
		"mistyped score": {GameSession.SCORE_KEY: "12"},
		"negative score": {GameSession.SCORE_KEY: -1},
		"highest level below the board": {GameSession.HIGHEST_LEVEL_KEY: BoardState.EMPTY_CELL},
	}

	for change_name: String in invalid_changes:
		var data: Dictionary = session.to_data()
		data.merge(invalid_changes[change_name], true)
		assert_null(GameSession.create_from_data(config, data), change_name)


func test_missing_value_is_not_restored() -> void:
	var session: GameSession = _create_playing_session()

	for key: String in session.to_data():
		var data: Dictionary = session.to_data()
		data.erase(key)
		assert_null(GameSession.create_from_data(_config, data), key)


func _create_playing_session() -> GameSession:
	return GameSession.new(_config, BalancingFixture.create_seeded_rng(SEED))


func _play_turns(session: GameSession, turn_count: int) -> void:
	for turn: int in turn_count:
		session.play_column(_find_first_playable_column(session))
	assert_false(session.is_game_over, "The fixture game must still be running")


func _find_first_playable_column(session: GameSession) -> int:
	for column: int in session.board.column_count_per_side:
		if session.can_play_column(column):
			return column
	return -1


func _describe_next_turn(session: GameSession) -> Array[int]:
	return [session.tile_generator.current_level, session.tile_generator.next_level, session.get_next_reflection_level()]


func _with_first_level(session: GameSession, level: int) -> PackedInt32Array:
	var levels: PackedInt32Array = session.board.get_levels()
	levels[0] = level
	return levels


## Empties the bottom cell of the first non-empty column, leaving the tiles above it in the air.
func _with_floating_tile(session: GameSession) -> PackedInt32Array:
	var levels: PackedInt32Array = session.board.get_levels()
	for column: int in session.board.get_column_count():
		if session.board.get_column_height(column) >= 2:
			levels[column * session.board.row_count] = BoardState.EMPTY_CELL
			return levels
	fail_test("The fixture board needs a column with two tiles")
	return levels


func _create_board_one_pair_from_full() -> BoardState:
	return BoardFixture.create_board([
		". 2 3 | 2 3 .",
		"2 3 2 | 3 2 3",
		"3 2 3 | 2 3 2",
		"2 3 2 | 3 2 3",
		"3 2 3 | 2 3 2",
		"2 3 2 | 3 2 3",
	])
