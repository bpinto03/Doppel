class_name ThemePreview
extends Control

## A tiny board in one theme, whatever the active one: the frame in its frame colors over its background,
## and tiles 2, 8, 64 and 1024 in a 2 × 2 grid, drawn with its own TilePainter. Frame sizes come from ShopPreviewFrame.

const TILE_TEXT_CONFIG: TileTextConfig = preload("res://data/tile_text.tres")
const PREVIEW_LEVELS: Array[int] = [1, 3, 6, 10]
const GRID_COLUMNS: int = 2
## Shares of the preview side kept around the tiles, and between them, as on the mockups.
const PADDING_RATIO: float = 0.08
const GAP_RATIO: float = 0.042

var palette: ThemePalette:
	set(value):
		palette = value
		_tile_painter = TilePainter.new(value, TILE_TEXT_CONFIG)
		queue_redraw()

var _tile_painter: TilePainter


func get_tile_painter() -> TilePainter:
	return _tile_painter


## The fill and border colors the frame is drawn with: those of the previewed theme.
func get_frame_colors() -> Array[Color]:
	return [palette.background, palette.frame_fill, palette.frame_border]


func _draw() -> void:
	if palette == null:
		return
	var frame_rect := Rect2(Vector2.ZERO, size)
	var background_box: StyleBoxFlat = _create_frame_box(palette.background, Color.TRANSPARENT)
	background_box.set_border_width_all(0)
	draw_style_box(background_box, frame_rect)
	draw_style_box(_create_frame_box(palette.frame_fill, palette.frame_border), frame_rect)
	_draw_tiles()


func _create_frame_box(fill_color: Color, border_color: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = get_theme_stylebox(&"panel", UiThemeBuilder.SHOP_PREVIEW_FRAME_TYPE).duplicate()
	box.bg_color = fill_color
	box.border_color = border_color
	return box


func _draw_tiles() -> void:
	var side: float = minf(size.x, size.y)
	var padding: float = side * PADDING_RATIO
	var gap: float = side * GAP_RATIO
	var row_count: int = ceili(float(PREVIEW_LEVELS.size()) / GRID_COLUMNS)
	var tile_size := Vector2(
		(size.x - 2.0 * padding - gap * (GRID_COLUMNS - 1)) / GRID_COLUMNS,
		(size.y - 2.0 * padding - gap * (row_count - 1)) / row_count
	)
	for index: int in PREVIEW_LEVELS.size():
		var cell := Vector2(index % GRID_COLUMNS, floori(float(index) / GRID_COLUMNS))
		var tile_position := Vector2(padding, padding) + cell * (tile_size + Vector2(gap, gap))
		_tile_painter.draw_tile(self, Rect2(tile_position, tile_size), PREVIEW_LEVELS[index])
