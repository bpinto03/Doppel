class_name TilePainter
extends RefCounted

## Text is measured at this size, then scaled: glyph widths grow linearly with the font size.
const REFERENCE_FONT_SIZE: int = 100
## Corner radius and relief are relative to the tile's shorter side, so stretched cells keep round corners.
const CORNER_RADIUS_RATIO: float = 0.12
const RELIEF_RATIO: float = 0.05
const RELIEF_DARKENING: float = 0.3
const CELL_OUTLINE_RATIO: float = 0.015
## Glow size relative to the tile's shorter side; its opacity comes from the palette.
const GLOW_SIZE_RATIO: float = 0.08
const TILE_OUTLINE_RATIO: float = 0.02
## Rim width of palettes with tile_rim_colors, relative to the tile's shorter side.
const TILE_RIM_RATIO: float = 0.04
const OUTLINE_DARKENING_STEP: float = 0.05

var palette: ThemePalette
var _text_config: TileTextConfig
var _tile_box := StyleBoxFlat.new()
## Per level, from level 1, decided once when the painter is built.
var _text_colors: Array[Color] = []
var _edge_colors: Array[Color] = []
var _outlined_levels: Array[bool] = []


func _init(theme_palette: ThemePalette, text_config: TileTextConfig) -> void:
	palette = theme_palette
	_text_config = text_config
	for level: int in range(1, palette.tile_colors.size() + 1):
		_text_colors.append(palette.pick_tile_text_color(level))
		if palette.has_tile_rims():
			_outlined_levels.append(true)
			_edge_colors.append(palette.tile_rim_colors[level - 1])
			continue
		var tile_color: Color = palette.get_tile_color(level)
		var is_outlined: bool = not stands_out_from_board(tile_color)
		_outlined_levels.append(is_outlined)
		_edge_colors.append(_find_outline_color(tile_color) if is_outlined else tile_color.darkened(RELIEF_DARKENING))


func draw_tile(canvas: CanvasItem, rect: Rect2, level: int, opacity: float = 1.0) -> void:
	if level == BoardState.EMPTY_CELL:
		_draw_empty_cell(canvas, rect, opacity)
		return
	var tile_color := Color(palette.get_tile_color(level), opacity)
	var relief: int = 0 if palette.has_tile_rims() else roundi(_get_shorter_side(rect) * RELIEF_RATIO)
	_set_up_box(rect, tile_color)
	if is_outlined(level):
		var outline_ratio: float = TILE_RIM_RATIO if palette.has_tile_rims() else TILE_OUTLINE_RATIO
		_tile_box.set_border_width_all(maxi(1, roundi(_get_shorter_side(rect) * outline_ratio)))
	if not palette.has_tile_rims():
		_tile_box.border_width_bottom = relief
	_tile_box.border_color = Color(get_edge_color(level), opacity)
	if palette.tile_glow_opacity > 0.0:
		_tile_box.shadow_color = Color(tile_color, palette.tile_glow_opacity * opacity)
		_tile_box.shadow_size = roundi(_get_shorter_side(rect) * GLOW_SIZE_RATIO)
	_tile_box.draw(canvas.get_canvas_item(), rect)
	var face := Rect2(rect.position, rect.size - Vector2(0.0, relief))
	_draw_value(canvas, face, str(MergeScoring.calculate_tile_value(level)), Color(get_text_color(level), opacity))


func get_text_color(level: int) -> Color:
	return _text_colors[level - 1]


## The relief color, which is also the outline color of an outlined tile, or the rim color when the palette has rims.
func get_edge_color(level: int) -> Color:
	return _edge_colors[level - 1]


func is_outlined(level: int) -> bool:
	return _outlined_levels[level - 1]


## The colors around a tile: empty cells, and the frame seen over the background between cells.
func get_board_backdrops() -> Array[Color]:
	return [palette.empty_cell, palette.background.blend(palette.frame_fill)]


func stands_out_from_board(color: Color) -> bool:
	for backdrop: Color in get_board_backdrops():
		if ColorContrast.calculate_ratio(color, backdrop) < palette.min_tile_edge_contrast:
			return false
	return true


## A faint fill, a solid outline and the value in the tile color, without relief, so a ghost never looks placed.
func draw_ghost_tile(canvas: CanvasItem, rect: Rect2, level: int, fill_opacity: float, outline_opacity: float, outline_width_ratio: float) -> void:
	var tile_color: Color = palette.get_tile_color(level)
	var outline_color := Color(tile_color, outline_opacity)
	draw_tile_shape(canvas, rect, Color(tile_color, fill_opacity))
	draw_tile_shape(canvas, rect, outline_color, calculate_ghost_outline_width(rect, outline_width_ratio))
	_draw_value(canvas, rect, str(MergeScoring.calculate_tile_value(level)), outline_color)


## Relative to the tile's shorter side, never thinner than a pixel.
func calculate_ghost_outline_width(rect: Rect2, outline_width_ratio: float) -> int:
	return maxi(1, roundi(_get_shorter_side(rect) * outline_width_ratio))


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


## Darker than the relief until it stands out from the board, or as dark as it gets.
func _find_outline_color(tile_color: Color) -> Color:
	var darkening: float = RELIEF_DARKENING
	while not stands_out_from_board(tile_color.darkened(darkening)) and darkening < 1.0:
		darkening += OUTLINE_DARKENING_STEP
	return tile_color.darkened(minf(darkening, 1.0))


func _draw_empty_cell(canvas: CanvasItem, rect: Rect2, opacity: float) -> void:
	_set_up_box(rect, Color(palette.empty_cell, opacity))
	_tile_box.set_border_width_all(maxi(1, roundi(_get_shorter_side(rect) * CELL_OUTLINE_RATIO)))
	_tile_box.border_color = Color(palette.cell_outline, opacity)
	_tile_box.draw(canvas.get_canvas_item(), rect)


## One box is reused for every tile: StyleBoxFlat.draw() records its current values at once.
func _set_up_box(rect: Rect2, color: Color) -> void:
	_tile_box.draw_center = true
	_tile_box.set_border_width_all(0)
	_tile_box.shadow_size = 0
	_tile_box.bg_color = color
	_tile_box.border_color = color
	_tile_box.set_corner_radius_all(roundi(_get_shorter_side(rect) * CORNER_RADIUS_RATIO))


func _draw_value(canvas: CanvasItem, rect: Rect2, text: String, color: Color) -> void:
	var font: Font = _text_config.font
	var font_size: int = calculate_font_size(text, rect.size)
	var baseline_y: float = rect.get_center().y + (font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0
	var baseline := Vector2(rect.position.x, baseline_y)
	canvas.draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, color)


func _get_shorter_side(rect: Rect2) -> float:
	return minf(rect.size.x, rect.size.y)
