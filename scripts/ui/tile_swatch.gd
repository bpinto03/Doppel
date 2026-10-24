class_name TileSwatch
extends Control

var level: int:
	set(value):
		level = value
		queue_redraw()


func _draw() -> void:
	TilePainter.draw_tile(self, Rect2(Vector2.ZERO, size), level)
