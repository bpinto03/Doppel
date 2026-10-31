class_name LogoMark
extends Control

## The game logo, drawn with the active palette: two overlapping circles, a four-pointed star above and below,
## and a dash on each side. Redrawn only when its size or the palette changes.

## Every length is relative to the logo height; the logo keeps this width to height ratio inside the control.
const WIDTH_RATIO: float = 1.32
const CIRCLE_RADIUS_RATIO: float = 0.279
## Distance from the logo center to each circle center.
const CIRCLE_OFFSET_RATIO: float = 0.171
const OUTLINE_WIDTH_RATIO: float = 0.011
const STAR_RADIUS_RATIO: float = 0.087
## Distance from the logo center to each star center.
const STAR_OFFSET_RATIO: float = 0.4
## Radius of the star waist, between two points, relative to the star radius.
const STAR_WAIST_RATIO: float = 0.36
const STAR_POINT_COUNT: int = 4
## Distance from the logo center to the inner end of each dash.
const DASH_OFFSET_RATIO: float = 0.54
const DASH_LENGTH_RATIO: float = 0.118
const DASH_WIDTH_RATIO: float = 0.012
## The glow is concentric rings around each shape, fading outwards; thin rings keep the steps between them invisible.
const GLOW_RING_COUNT: int = 10
const GLOW_RING_WIDTH_RATIO: float = 0.005
const ARC_POINT_COUNT: int = 96

var _palette: ThemePalette


func _ready() -> void:
	Settings.palette_changed.connect(_on_palette_changed)
	resized.connect(queue_redraw)
	_palette = Settings.get_palette()


func _draw() -> void:
	var height: float = minf(size.y, size.x / WIDTH_RATIO)
	var center: Vector2 = size / 2.0
	var circle_radius: float = height * CIRCLE_RADIUS_RATIO
	var left_center: Vector2 = center - Vector2(height * CIRCLE_OFFSET_RATIO, 0.0)
	var right_center: Vector2 = center + Vector2(height * CIRCLE_OFFSET_RATIO, 0.0)
	var star_offset := Vector2(0.0, height * STAR_OFFSET_RATIO)
	var star_radius: float = height * STAR_RADIUS_RATIO
	if _palette.logo_glow.a > 0.0:
		var ring_width: float = height * GLOW_RING_WIDTH_RATIO
		for circle_center: Vector2 in [left_center, right_center]:
			_draw_glow(circle_center, circle_radius, ring_width)
		for star_center: Vector2 in [center - star_offset, center + star_offset]:
			_draw_glow(star_center, star_radius * STAR_WAIST_RATIO, ring_width)
	var outline_width: float = height * OUTLINE_WIDTH_RATIO
	_draw_circle(left_center, circle_radius, _palette.logo_left_fill, _palette.logo_left_outline, outline_width)
	_draw_circle(right_center, circle_radius, _palette.logo_right_fill, _palette.logo_right_outline, outline_width)
	for star_center: Vector2 in [center - star_offset, center + star_offset]:
		draw_colored_polygon(_build_star(star_center, star_radius), _palette.logo_accent)
	_draw_dashes(center, height)


func _on_palette_changed() -> void:
	_palette = Settings.get_palette()
	queue_redraw()


func _draw_circle(circle_center: Vector2, radius: float, fill: Color, outline: Color, outline_width: float) -> void:
	draw_circle(circle_center, radius, fill, true, -1.0, true)
	draw_arc(circle_center, radius, 0.0, TAU, ARC_POINT_COUNT, outline, outline_width, true)


## Each ring is fainter than the one inside it, so the glow fades without a blur.
func _draw_glow(glow_center: Vector2, radius: float, ring_width: float) -> void:
	for ring: int in GLOW_RING_COUNT:
		var fade: float = pow(1.0 - float(ring) / GLOW_RING_COUNT, 2.0)
		var ring_radius: float = radius + ring_width * (ring + 0.5)
		draw_arc(glow_center, ring_radius, 0.0, TAU, ARC_POINT_COUNT, Color(_palette.logo_glow, _palette.logo_glow.a * fade), ring_width, true)


func _build_star(star_center: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for corner: int in STAR_POINT_COUNT * 2:
		var corner_radius: float = radius if corner % 2 == 0 else radius * STAR_WAIST_RATIO
		var angle: float = -PI / 2.0 + PI * corner / STAR_POINT_COUNT
		points.append(star_center + Vector2.from_angle(angle) * corner_radius)
	return points


func _draw_dashes(center: Vector2, height: float) -> void:
	var dash_width: float = height * DASH_WIDTH_RATIO
	for direction: float in [-1.0, 1.0]:
		var inner_end: Vector2 = center + Vector2(direction * height * DASH_OFFSET_RATIO, 0.0)
		var outer_end: Vector2 = inner_end + Vector2(direction * height * DASH_LENGTH_RATIO, 0.0)
		draw_line(inner_end, outer_end, _palette.logo_accent, dash_width)
