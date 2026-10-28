extends GutTest

const TILE_TEXT_CONFIG: TileTextConfig = preload("res://data/tile_text.tres")
const TILE_SIZE := Vector2(150.0, 150.0)
const GHOST_OUTLINE_WIDTH_RATIO: float = 0.05

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


func test_ghost_outline_follows_the_tile_size() -> void:
	var large_width: int = _painter.calculate_ghost_outline_width(Rect2(Vector2.ZERO, TILE_SIZE), GHOST_OUTLINE_WIDTH_RATIO)
	var small_width: int = _painter.calculate_ghost_outline_width(Rect2(Vector2.ZERO, TILE_SIZE / 2.0), GHOST_OUTLINE_WIDTH_RATIO)

	assert_eq(large_width, roundi(TILE_SIZE.x * GHOST_OUTLINE_WIDTH_RATIO))
	assert_lt(small_width, large_width)


func test_ghost_outline_is_never_thinner_than_a_pixel() -> void:
	assert_eq(_painter.calculate_ghost_outline_width(Rect2(Vector2.ZERO, Vector2.ONE), GHOST_OUTLINE_WIDTH_RATIO), 1)
