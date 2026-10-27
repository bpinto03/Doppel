class_name TilePainter
extends RefCounted

## Text is measured at this size, then scaled: glyph widths grow linearly with the font size.
const REFERENCE_FONT_SIZE: int = 100
## Corner radius and relief are relative to the tile's shorter side, so stretched cells keep round corners.
const CORNER_RADIUS_RATIO: float = 0.16
const RELIEF_RATIO: float = 0.05
const RELIEF_DARKENING: float = 0.3
## Empty cells look sunken: a darker top border, the reverse of the tile relief.
const HOLLOW_DEPTH_RATIO: float = 0.04
const HOLLOW_DARKENING: float = 0.12

var palette: ThemePalette
var _text_config: TileTextConfig
var _tile_box := StyleBoxFlat.new()


func _init(theme_palette: ThemePalette, text_config: TileTextConfig) -> void:
	palette = theme_palette
	_text_config = text_config


func draw_tile(canvas: CanvasItem, rect: Rect2, level: int, opacity: float = 1.0) -> void:
	if level == BoardState.EMPTY_CELL:
		_draw_hollow(canvas, rect, Color(palette.empty_cell, opacity))
		return
	var tile_color := Color(palette.get_tile_color(level), opacity)
	var relief: int = roundi(_get_shorter_side(rect) * RELIEF_RATIO)
	_set_up_box(rect, tile_color)
	_tile_box.border_width_bottom = relief
	_tile_box.border_color = tile_color.darkened(RELIEF_DARKENING)
	_tile_box.draw(canvas.get_canvas_item(), rect)
	var face := Rect2(rect.position, rect.size - Vector2(0.0, relief))
	_draw_value(canvas, face, str(MergeScoring.calculate_tile_value(level)), opacity)


## Fills or outlines the tile shape without relief, for overlays.
func draw_tile_shape(canvas: CanvasItem, rect: Rect2, color: Color, outline_width: int = 0) -> void:
	_set_up_box(rect, color)
	_tile_box.draw_center = outline_width == 0
	_tile_box.set_border_width_all(outline_width)
	_tile_box.draw(canvas.get_canvas_item(), rect)


func calculate_font_size(text: String, tile_size: Vector2) -> int:
	var font: Font = _text_config.font
	var reference_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, REFERENCE_FONT_SIZE).x
	var width_limited_size: float = REFERENCE_FONT_SIZE * tile_size.x * _text_config.max_width_ratio / reference_width
	var height_limited_size: float = tile_size.y * _text_config.max_height_ratio
	return floori(minf(width_limited_size, height_limited_size))


func _draw_hollow(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	_set_up_box(rect, color)
	_tile_box.border_width_top = roundi(_get_shorter_side(rect) * HOLLOW_DEPTH_RATIO)
	_tile_box.border_color = color.darkened(HOLLOW_DARKENING)
	_tile_box.draw(canvas.get_canvas_item(), rect)


## One box is reused for every tile: StyleBoxFlat.draw() records its current values at once.
func _set_up_box(rect: Rect2, color: Color) -> void:
	_tile_box.draw_center = true
	_tile_box.set_border_width_all(0)
	_tile_box.bg_color = color
	_tile_box.border_color = color
	_tile_box.set_corner_radius_all(roundi(_get_shorter_side(rect) * CORNER_RADIUS_RATIO))


func _draw_value(canvas: CanvasItem, rect: Rect2, text: String, opacity: float) -> void:
	var font: Font = _text_config.font
	var font_size: int = calculate_font_size(text, rect.size)
	var baseline_y: float = rect.get_center().y + (font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0
	var baseline := Vector2(rect.position.x, baseline_y)
	canvas.draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, Color(palette.tile_text, opacity))


func _get_shorter_side(rect: Rect2) -> float:
	return minf(rect.size.x, rect.size.y)
