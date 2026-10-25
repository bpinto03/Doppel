extends GutTest

const BOTTOM_ROW_INDEX: int = 5
const SECOND_ROW_INDEX: int = 4


func test_tutorial_has_three_steps_in_order() -> void:
	var steps: Array[TutorialStep] = TutorialScenarios.create_steps()

	assert_eq(steps.size(), 3)
	assert_eq(steps[0].instruction_key, &"TUTORIAL_STEP_1")
	assert_eq(steps[1].instruction_key, &"TUTORIAL_STEP_2")
	assert_eq(steps[2].instruction_key, &"TUTORIAL_STEP_3")


func test_every_target_column_is_playable_at_step_start() -> void:
	for step: TutorialStep in TutorialScenarios.create_steps():
		assert_true(step.create_session().can_play_column(step.target_column))


func test_drop_step_reflects_tile_without_merging() -> void:
	var session: GameSession = TutorialScenarios.create_drop_step().create_session()

	var result: ChainResult = session.play_column(TutorialScenarios.OUTER_LEFT_COLUMN)

	assert_eq(BoardFixture.describe_board(session.board)[BOTTOM_ROW_INDEX], "1 . . | . . 1")
	assert_eq(result.chain_length, 0)
	assert_eq(session.score, 0)


func test_merge_step_merges_identical_tiles_on_both_sides() -> void:
	var session: GameSession = TutorialScenarios.create_merge_step().create_session()

	var result: ChainResult = session.play_column(TutorialScenarios.OUTER_LEFT_COLUMN)

	assert_eq(BoardFixture.describe_board(session.board)[SECOND_ROW_INDEX], ". . . | . . .")
	assert_eq(BoardFixture.describe_board(session.board)[BOTTOM_ROW_INDEX], "2 . . | . . 2")
	assert_eq(result.chain_length, 1)
	assert_eq(session.score, 8)


func test_axis_step_merges_placed_tile_with_waiting_tile_across_axis() -> void:
	var session: GameSession = TutorialScenarios.create_axis_step().create_session()

	var result: ChainResult = session.play_column(TutorialScenarios.AXIS_LEFT_COLUMN)

	assert_eq(BoardFixture.describe_board(session.board)[SECOND_ROW_INDEX], ". . . | 2 . .")
	assert_eq(BoardFixture.describe_board(session.board)[BOTTOM_ROW_INDEX], ". . 3 | 1 . .")
	assert_eq(result.chain_length, 1)
	assert_eq(result.highest_level_created, 3)
	assert_eq(session.score, 8)


func test_tutorial_rules_ignore_shipped_balancing() -> void:
	var config: BalancingConfig = TutorialStep.create_config()

	assert_eq(config.column_count_per_side, 3)
	assert_eq(config.row_count, 6)
	assert_false(config.is_distorted_reflection_enabled)


func test_next_preview_stays_predictable_after_scripted_tiles() -> void:
	var session: GameSession = TutorialScenarios.create_drop_step().create_session()

	session.play_column(TutorialScenarios.OUTER_LEFT_COLUMN)

	assert_eq(session.tile_generator.next_level, TutorialStep.FALLBACK_TILE_LEVEL)
