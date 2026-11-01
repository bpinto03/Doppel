class_name SurfaceGrain
extends RefCounted

## Draws a palette's grain overlay (surface_grain) over a StyleBoxFlat surface, inside its rounded corners.
## The overlay is black or white with the grain in its alpha, so at an opacity it darkens or lightens the surface
## by at most that opacity; tests/test_theme_palettes.gd checks text contrast at both extremes.

const CORNER_SEGMENTS: int = 6
## Spread the overlay region picked for each surface, so neighbor tiles and cells never show the same grain.
const OFFSET_SPREAD := Vector2(0.618, 1.732)


static func draw_over_box(canvas_item: RID, rect: Rect2, box: StyleBoxFlat, texture: Texture2D, opacity: float) -> void:
	if texture == null or opacity <= 0.0:
		return
	var surface: Rect2 = rect.grow_individual(box.expand_margin_left, box.expand_margin_top, box.expand_margin_right, box.expand_margin_bottom)
	var radii := Vector4(box.corner_radius_top_left, box.corner_radius_top_right, box.corner_radius_bottom_right, box.corner_radius_bottom_left)
	var points: PackedVector2Array = _build_rounded_rect(surface, radii)
	var colors := PackedColorArray()
	colors.resize(points.size())
	colors.fill(Color(1.0, 1.0, 1.0, opacity))
	RenderingServer.canvas_item_add_polygon(canvas_item, points, colors, _map_to_texture(points, surface, texture.get_size()), texture.get_rid())


## The overlay is drawn at its own pixel size, from a region picked by the surface position; a surface larger
## than the overlay stretches it instead of repeating it, since the grain picture is not seamless.
static func _map_to_texture(points: PackedVector2Array, surface: Rect2, texture_size: Vector2) -> PackedVector2Array:
	var scale: float = maxf(1.0, maxf(surface.size.x / texture_size.x, surface.size.y / texture_size.y))
	var region_size: Vector2 = surface.size / scale
	var free_room: Vector2 = (texture_size - region_size).max(Vector2.ONE)
	var region_origin := Vector2(
		fposmod(surface.position.x * OFFSET_SPREAD.x + surface.position.y * OFFSET_SPREAD.y, free_room.x),
		fposmod(surface.position.y * OFFSET_SPREAD.x + surface.position.x * OFFSET_SPREAD.y, free_room.y)
	)
	var uvs := PackedVector2Array()
	for point: Vector2 in points:
		uvs.append((region_origin + (point - surface.position) / scale) / texture_size)
	return uvs


## Corners in StyleBoxFlat order: top left, top right, bottom right, bottom left; each radius is capped at half
## the shorter side, as StyleBoxFlat does.
static func _build_rounded_rect(rect: Rect2, radii: Vector4) -> PackedVector2Array:
	var largest_radius: float = minf(rect.size.x, rect.size.y) / 2.0
	var corner_centers: Array[Vector2] = [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	var inward: Array[Vector2] = [Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1), Vector2(1, -1)]
	var points := PackedVector2Array()
	for corner: int in 4:
		var radius: float = minf(radii[corner], largest_radius)
		var center: Vector2 = corner_centers[corner] + inward[corner] * radius
		var start_angle: float = PI + corner * PI / 2.0
		for segment: int in CORNER_SEGMENTS + 1:
			var angle: float = start_angle + segment * (PI / 2.0) / CORNER_SEGMENTS
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points
