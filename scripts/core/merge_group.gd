class_name MergeGroup
extends RefCounted

var level: int
var cells: Array[Vector2i]


func _init(group_level: int, group_cells: Array[Vector2i]) -> void:
	level = group_level
	cells = group_cells


func is_crossing_axis(board: BoardState) -> bool:
	var has_left_cell: bool = false
	var has_right_cell: bool = false
	for cell: Vector2i in cells:
		if board.is_left_column(cell.x):
			has_left_cell = true
		else:
			has_right_cell = true
	return has_left_cell and has_right_cell
