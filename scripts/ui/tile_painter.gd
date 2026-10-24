class_name TilePainter
extends RefCounted

const EMPTY_CELL_COLOR := Color("#2a2f3a")
const VALUE_TEXT_COLOR := Color.WHITE
const VALUE_FONT_SIZE_RATIO: float = 0.34
const LEVEL_COLORS: Array[Color] = [
	Color("#5b8def"),
	Color("#3fb4c9"),
	Color("#3cb878"),
	Color("#86c540"),
	Color("#d9b42a"),
	Color("#ef8f2f"),
	Color("#e8603f"),
	Color("#dc3f73"),
	Color("#b04fd0"),
	Color("#7754e8"),
	Color("#4146c9"),
	Color("#1f1f2e"),
]


static func draw_tile(canvas: CanvasItem, rect: Rect2, level: int) -> void:
	if level == BoardState.EMPTY_CELL:
		canvas.draw_rect(rect, EMPTY_CELL_COLOR)
		return
	canvas.draw_rect(rect, LEVEL_COLORS[(level - 1) % LEVEL_COLORS.size()])
	_draw_value(canvas, rect, str(MergeScoring.calculate_tile_value(level)))


static func _draw_value(canvas: CanvasItem, rect: Rect2, text: String) -> void:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = roundi(minf(rect.size.x, rect.size.y) * VALUE_FONT_SIZE_RATIO)
	var baseline_y: float = rect.get_center().y + (font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0
	var baseline := Vector2(rect.position.x, baseline_y)
	canvas.draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, VALUE_TEXT_COLOR)
