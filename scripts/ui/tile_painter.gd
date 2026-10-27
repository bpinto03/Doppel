class_name TilePainter
extends RefCounted

## Text is measured at this size, then scaled: glyph widths grow linearly with the font size.
const REFERENCE_FONT_SIZE: int = 100

var palette: ThemePalette
var _text_config: TileTextConfig


func _init(theme_palette: ThemePalette, text_config: TileTextConfig) -> void:
	palette = theme_palette
	_text_config = text_config


func draw_tile(canvas: CanvasItem, rect: Rect2, level: int, opacity: float = 1.0) -> void:
	if level == BoardState.EMPTY_CELL:
		canvas.draw_rect(rect, Color(palette.empty_cell, opacity))
		return
	canvas.draw_rect(rect, Color(palette.get_tile_color(level), opacity))
	_draw_value(canvas, rect, str(MergeScoring.calculate_tile_value(level)), opacity)


func calculate_font_size(text: String, tile_size: Vector2) -> int:
	var font: Font = _text_config.font
	var reference_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, REFERENCE_FONT_SIZE).x
	var width_limited_size: float = REFERENCE_FONT_SIZE * tile_size.x * _text_config.max_width_ratio / reference_width
	var height_limited_size: float = tile_size.y * _text_config.max_height_ratio
	return floori(minf(width_limited_size, height_limited_size))


func _draw_value(canvas: CanvasItem, rect: Rect2, text: String, opacity: float) -> void:
	var font: Font = _text_config.font
	var font_size: int = calculate_font_size(text, rect.size)
	var baseline_y: float = rect.get_center().y + (font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0
	var baseline := Vector2(rect.position.x, baseline_y)
	canvas.draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, Color(palette.tile_text, opacity))
