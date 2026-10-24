class_name BoardState
extends RefCounted

## Cells are addressed as Vector2i(column, row). Row 0 is the bottom of the board.
## Columns [0, column_count_per_side) are on the left of the mirror axis.

const EMPTY_CELL: int = 0
const SIDE_COUNT: int = 2
const ORTHOGONAL_DIRECTIONS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var column_count_per_side: int
var row_count: int
var _levels: PackedInt32Array


func _init(columns_per_side: int, rows: int) -> void:
	column_count_per_side = columns_per_side
	row_count = rows
	_levels.resize(get_column_count() * row_count)


func get_column_count() -> int:
	return column_count_per_side * SIDE_COUNT


func get_level(cell: Vector2i) -> int:
	return _levels[_to_index(cell)]


func set_level(cell: Vector2i, level: int) -> void:
	_levels[_to_index(cell)] = level


func is_empty(cell: Vector2i) -> bool:
	return get_level(cell) == EMPTY_CELL


func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < get_column_count() and cell.y >= 0 and cell.y < row_count


func is_left_column(column: int) -> bool:
	return column >= 0 and column < column_count_per_side


func get_mirror_column(column: int) -> int:
	return get_column_count() - 1 - column


func get_distance_to_axis(column: int) -> int:
	if is_left_column(column):
		return column_count_per_side - 1 - column
	return column - column_count_per_side


func get_column_height(column: int) -> int:
	var height: int = 0
	for row: int in row_count:
		if not is_empty(Vector2i(column, row)):
			height += 1
	return height


func is_column_full(column: int) -> bool:
	return get_column_height(column) >= row_count


func get_orthogonal_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for direction: Vector2i in ORTHOGONAL_DIRECTIONS:
		var neighbor: Vector2i = cell + direction
		if is_inside(neighbor):
			neighbors.append(neighbor)
	return neighbors


## Expects a settled column. Returns the cell where the tile landed.
func drop_tile(column: int, level: int) -> Vector2i:
	assert(not is_column_full(column), "Cannot drop a tile in full column %d" % column)
	var landing_cell := Vector2i(column, get_column_height(column))
	set_level(landing_cell, level)
	return landing_cell


## Returns the new position of every tile that fell.
func apply_gravity() -> Array[Vector2i]:
	var fallen_cells: Array[Vector2i] = []
	for column: int in get_column_count():
		fallen_cells.append_array(_settle_column(column))
	return fallen_cells


func _settle_column(column: int) -> Array[Vector2i]:
	var fallen_cells: Array[Vector2i] = []
	var landing_row: int = 0
	for row: int in row_count:
		var level: int = get_level(Vector2i(column, row))
		if level == EMPTY_CELL:
			continue
		if row != landing_row:
			set_level(Vector2i(column, landing_row), level)
			set_level(Vector2i(column, row), EMPTY_CELL)
			fallen_cells.append(Vector2i(column, landing_row))
		landing_row += 1
	return fallen_cells


func _to_index(cell: Vector2i) -> int:
	assert(is_inside(cell), "Cell %s is outside the board" % cell)
	return cell.x * row_count + cell.y
