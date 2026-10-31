class_name CrownHalo
extends Control

## Soft light behind the game over crown: a disc fading to its edge, and thin rays.
## Drawn once per size or color; vertex colors make the fades, without a shader.

const EDGE_POINT_COUNT: int = 64
const RAY_COUNT: int = 8
## Half the angle of a ray at the center, in radians.
const RAY_HALF_WIDTH: float = 0.07
const RAY_OPACITY: float = 0.6
## The disc reaches this share of the radius; rays reach the edge.
const DISC_RADIUS_RATIO: float = 0.7

## A transparent color draws nothing.
var color := Color.TRANSPARENT:
	set(value):
		color = value
		queue_redraw()


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	if color.a <= 0.0:
		return
	var center: Vector2 = size / 2.0
	var radius: float = minf(size.x, size.y) / 2.0
	_draw_disc(center, radius * DISC_RADIUS_RATIO)
	for ray: int in RAY_COUNT:
		_draw_ray(center, radius, TAU * ray / RAY_COUNT)


func _draw_disc(center: Vector2, radius: float) -> void:
	var edge := Color(color, 0.0)
	for point: int in EDGE_POINT_COUNT:
		var from_angle: float = TAU * point / EDGE_POINT_COUNT
		var to_angle: float = TAU * (point + 1) / EDGE_POINT_COUNT
		var triangle := PackedVector2Array([center, center + Vector2.from_angle(from_angle) * radius, center + Vector2.from_angle(to_angle) * radius])
		draw_polygon(triangle, PackedColorArray([color, edge, edge]))


func _draw_ray(center: Vector2, radius: float, angle: float) -> void:
	var ray_color := Color(color, color.a * RAY_OPACITY)
	var edge := Color(color, 0.0)
	var triangle := PackedVector2Array([
		center,
		center + Vector2.from_angle(angle - RAY_HALF_WIDTH) * radius,
		center + Vector2.from_angle(angle + RAY_HALF_WIDTH) * radius,
	])
	draw_polygon(triangle, PackedColorArray([ray_color, edge, edge]))
