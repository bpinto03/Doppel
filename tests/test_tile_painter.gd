extends GutTest

const TILE_TEXT_CONFIG: TileTextConfig = preload("res://data/tile_text.tres")
const TILE_SIZE := Vector2(150.0, 150.0)

var _painter: TilePainter


func before_each() -> void:
	_painter = TilePainter.new(preload("res://data/palette_paper.tres"), TILE_TEXT_CONFIG)


func test_short_value_is_limited_by_the_tile_height() -> void:
	var font_size: int = _painter.calculate_font_size("2", TILE_SIZE)

	assert_eq(font_size, floori(TILE_SIZE.y * TILE_TEXT_CONFIG.max_height_ratio))


func test_longest_value_shrinks_to_fit_the_tile_width() -> void:
	var font_size: int = _painter.calculate_font_size("4096", TILE_SIZE)
	var text_width: float = TILE_TEXT_CONFIG.font.get_string_size("4096", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

	assert_lt(font_size, _painter.calculate_font_size("2", TILE_SIZE))
	assert_lte(text_width, TILE_SIZE.x * TILE_TEXT_CONFIG.max_width_ratio)
