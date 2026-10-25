class_name MergeResolver
extends RefCounted

const MIN_GROUP_SIZE: int = 2

var _config: BalancingConfig


func _init(config: BalancingConfig) -> void:
	_config = config


## Merges every group, applies gravity, and repeats until the board is stable.
## Each pass is one link of the chain.
func resolve_chain(board: BoardState, placed_cells: Array[Vector2i]) -> ChainResult:
	var result := ChainResult.new()
	var recently_moved_cells: Array[Vector2i] = placed_cells.duplicate()
	var groups: Array[MergeGroup] = find_merge_groups(board)
	while not groups.is_empty():
		result.chain_length += 1
		recently_moved_cells = _merge_groups(board, groups, recently_moved_cells, result)
		recently_moved_cells.append_array(_apply_gravity(board, result))
		groups = find_merge_groups(board)
	return result


func find_merge_groups(board: BoardState) -> Array[MergeGroup]:
	var groups: Array[MergeGroup] = []
	var visited_cells: Dictionary[Vector2i, bool] = {}
	for column: int in board.get_column_count():
		for row: int in board.row_count:
			var cell := Vector2i(column, row)
			if visited_cells.has(cell) or not _is_mergeable(board, cell):
				continue
			var group_cells: Array[Vector2i] = _collect_connected_cells(board, cell, visited_cells)
			if group_cells.size() >= MIN_GROUP_SIZE:
				groups.append(MergeGroup.new(board.get_level(cell), group_cells))
	return groups


## Axis rule first: a group touching both sides lands on the left side.
## Otherwise the result lands where the player's action happened.
func choose_result_cell(board: BoardState, group: MergeGroup, recently_moved_cells: Array[Vector2i]) -> Vector2i:
	if group.is_crossing_axis(board):
		return _find_lowest_cell_closest_to_axis(board, _filter_left_cells(board, group.cells))
	var moved_group_cells: Array[Vector2i] = _filter_cells_in(group.cells, recently_moved_cells)
	if not moved_group_cells.is_empty():
		return _find_lowest_cell_closest_to_axis(board, moved_group_cells)
	return _find_lowest_cell_closest_to_axis(board, group.cells)


func _is_mergeable(board: BoardState, cell: Vector2i) -> bool:
	var level: int = board.get_level(cell)
	return level != BoardState.EMPTY_CELL and level < _config.max_tile_level


func _collect_connected_cells(board: BoardState, start_cell: Vector2i, visited_cells: Dictionary[Vector2i, bool]) -> Array[Vector2i]:
	var level: int = board.get_level(start_cell)
	var connected_cells: Array[Vector2i] = []
	var cells_to_visit: Array[Vector2i] = [start_cell]
	visited_cells[start_cell] = true
	while not cells_to_visit.is_empty():
		var cell: Vector2i = cells_to_visit.pop_back()
		connected_cells.append(cell)
		for neighbor: Vector2i in board.get_orthogonal_neighbors(cell):
			if not visited_cells.has(neighbor) and board.get_level(neighbor) == level:
				visited_cells[neighbor] = true
				cells_to_visit.append(neighbor)
	return connected_cells


## Returns the cells holding the merged tiles.
func _merge_groups(board: BoardState, groups: Array[MergeGroup], recently_moved_cells: Array[Vector2i], result: ChainResult) -> Array[Vector2i]:
	var result_cells: Array[Vector2i] = []
	for group: MergeGroup in groups:
		var result_cell: Vector2i = choose_result_cell(board, group, recently_moved_cells)
		var result_level: int = group.level + 1
		var points: int = MergeScoring.calculate_merge_points(result_level, group.cells.size(), result.chain_length, _config)
		var multiplier: float = MergeScoring.calculate_chain_multiplier(result.chain_length, _config)
		var event := GroupMergedEvent.new(result.chain_length, multiplier, group, result_cell, points, group.is_crossing_axis(board))
		event.apply_to(board)
		result.events.append(event)
		result_cells.append(result_cell)
		result.points_earned += points
		result.highest_level_created = maxi(result.highest_level_created, result_level)
	return result_cells


## Returns the cells where tiles landed.
func _apply_gravity(board: BoardState, result: ChainResult) -> Array[Vector2i]:
	var falls: Array[TileFall] = board.apply_gravity()
	if falls.is_empty():
		return []
	result.events.append(TilesFellEvent.new(result.chain_length, falls))
	var landing_cells: Array[Vector2i] = []
	for fall: TileFall in falls:
		landing_cells.append(fall.to_cell)
	return landing_cells


func _find_lowest_cell_closest_to_axis(board: BoardState, cells: Array[Vector2i]) -> Vector2i:
	var best_cell: Vector2i = cells[0]
	for cell: Vector2i in cells:
		var is_lower: bool = cell.y < best_cell.y
		var is_closer_at_same_row: bool = cell.y == best_cell.y and board.get_distance_to_axis(cell.x) < board.get_distance_to_axis(best_cell.x)
		if is_lower or is_closer_at_same_row:
			best_cell = cell
	return best_cell


func _filter_left_cells(board: BoardState, cells: Array[Vector2i]) -> Array[Vector2i]:
	var left_cells: Array[Vector2i] = []
	for cell: Vector2i in cells:
		if board.is_left_column(cell.x):
			left_cells.append(cell)
	return left_cells


func _filter_cells_in(cells: Array[Vector2i], allowed_cells: Array[Vector2i]) -> Array[Vector2i]:
	var kept_cells: Array[Vector2i] = []
	for cell: Vector2i in cells:
		if allowed_cells.has(cell):
			kept_cells.append(cell)
	return kept_cells
