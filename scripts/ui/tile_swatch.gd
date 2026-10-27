class_name TileSwatch
extends Control

var level: int:
	set(value):
		level = value
		queue_redraw()
var tile_painter: TilePainter:
	set(value):
		tile_painter = value
		queue_redraw()


func _draw() -> void:
	if tile_painter != null:
		tile_painter.draw_tile(self, Rect2(Vector2.ZERO, size), level)
