class_name GroupMergedEvent
extends ResolutionEvent

var chain_link: int
var chain_multiplier: float
var group_cells: Array[Vector2i]
var group_level: int
var result_cell: Vector2i
var result_level: int
var points_earned: int
var is_crossing_axis: bool


func _init(link: int, multiplier: float, group: MergeGroup, landing_cell: Vector2i, points: int, crosses_axis: bool) -> void:
	chain_link = link
	chain_multiplier = multiplier
	group_cells = group.cells.duplicate()
	group_level = group.level
	result_cell = landing_cell
	result_level = group.level + 1
	points_earned = points
	is_crossing_axis = crosses_axis


func apply_to(board: BoardState) -> void:
	for cell: Vector2i in group_cells:
		board.set_level(cell, BoardState.EMPTY_CELL)
	board.set_level(result_cell, result_level)
