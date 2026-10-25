class_name TilesPlacedEvent
extends ResolutionEvent

var tile_cell: Vector2i
var tile_level: int
var reflection_cell: Vector2i
var reflection_level: int
var is_reflection_distorted: bool


func _init(placed_cell: Vector2i, placed_level: int, mirror_cell: Vector2i, mirror_level: int, is_distorted: bool) -> void:
	tile_cell = placed_cell
	tile_level = placed_level
	reflection_cell = mirror_cell
	reflection_level = mirror_level
	is_reflection_distorted = is_distorted


func apply_to(board: BoardState) -> void:
	board.set_level(tile_cell, tile_level)
	board.set_level(reflection_cell, reflection_level)
