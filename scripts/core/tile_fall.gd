class_name TileFall
extends RefCounted

var from_cell: Vector2i
var to_cell: Vector2i
var level: int


func _init(origin_cell: Vector2i, landing_cell: Vector2i, tile_level: int) -> void:
	from_cell = origin_cell
	to_cell = landing_cell
	level = tile_level
