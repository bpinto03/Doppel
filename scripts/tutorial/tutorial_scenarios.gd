class_name TutorialScenarios
extends RefCounted

const OUTER_LEFT_COLUMN: int = 0
const AXIS_LEFT_COLUMN: int = 2
const AXIS_RIGHT_COLUMN: int = 3
const OUTER_RIGHT_COLUMN: int = 5
const BOTTOM_ROW: int = 0


static func create_steps() -> Array[TutorialStep]:
	return [create_drop_step(), create_merge_step(), create_axis_step()]


static func create_drop_step() -> TutorialStep:
	return TutorialStep.new(&"TUTORIAL_STEP_1", &"TUTORIAL_STEP_1_DONE", {}, [1, 1], OUTER_LEFT_COLUMN)


## Starts from the board left by the drop step: a tile and its reflection on the outer columns.
static func create_merge_step() -> TutorialStep:
	var tile_cell := Vector2i(OUTER_LEFT_COLUMN, BOTTOM_ROW)
	var reflection_cell := Vector2i(OUTER_RIGHT_COLUMN, BOTTOM_ROW)
	return TutorialStep.new(
		&"TUTORIAL_STEP_2", &"TUTORIAL_STEP_2_DONE", {tile_cell: 1, reflection_cell: 1}, [1, 1], OUTER_LEFT_COLUMN, [tile_cell, reflection_cell]
	)


## A level 1 tile sits on the waiting tile so the reflection lands above it:
## only the placed tile and the waiting tile merge, across the axis.
static func create_axis_step() -> TutorialStep:
	var waiting_cell := Vector2i(AXIS_RIGHT_COLUMN, BOTTOM_ROW)
	var blocker_cell := Vector2i(AXIS_RIGHT_COLUMN, BOTTOM_ROW + 1)
	var landing_cell := Vector2i(AXIS_LEFT_COLUMN, BOTTOM_ROW)
	return TutorialStep.new(
		&"TUTORIAL_STEP_3", &"TUTORIAL_STEP_3_DONE", {waiting_cell: 2, blocker_cell: 1}, [2, 1], AXIS_LEFT_COLUMN, [landing_cell, waiting_cell], true
	)
