extends GutTest

const MIN_TILE_TEXT_CONTRAST: float = 4.5
const LEVEL_COUNT: int = 12
const TILE_TEXT_CONFIG: TileTextConfig = preload("res://data/tile_text.tres")
## The Night tile text before tiles could take a light text: Night tiles are all light, so it must not change.
const NIGHT_TILE_TEXT := Color(0.07843, 0.08627, 0.1216, 1)


func test_every_palette_has_one_color_per_level() -> void:
	for palette_name: String in Settings.PALETTES:
		assert_eq(Settings.PALETTES[palette_name].tile_colors.size(), LEVEL_COUNT, palette_name)


func test_tile_text_is_readable_on_every_tile() -> void:
	for palette_name: String in Settings.PALETTES:
		var painter := TilePainter.new(Settings.PALETTES[palette_name], TILE_TEXT_CONFIG)
		for level: int in range(1, LEVEL_COUNT + 1):
			var contrast: float = ColorContrast.calculate_ratio(painter.get_text_color(level), painter.palette.get_tile_color(level))
			assert_gte(contrast, MIN_TILE_TEXT_CONTRAST, "%s level %d" % [palette_name, level])


func test_night_tiles_keep_their_near_black_text() -> void:
	var painter := TilePainter.new(Settings.PALETTES["night"], TILE_TEXT_CONFIG)

	for level: int in range(1, LEVEL_COUNT + 1):
		assert_eq(painter.get_text_color(level), NIGHT_TILE_TEXT, "level %d" % level)


func test_each_tile_takes_the_text_color_with_the_higher_contrast() -> void:
	var palette := ThemePalette.new()
	palette.tile_text_dark = Color.BLACK
	palette.tile_text_light = Color.WHITE
	palette.tile_colors = [Color("1f3a68"), Color("f9d066")]

	assert_eq(palette.pick_tile_text_color(1), Color.WHITE, "Dark tile")
	assert_eq(palette.pick_tile_text_color(2), Color.BLACK, "Light tile")


func test_contrast_ratio_spans_one_to_twenty_one() -> void:
	assert_almost_eq(ColorContrast.calculate_ratio(Color.BLACK, Color.WHITE), 21.0, 0.01)
	assert_almost_eq(ColorContrast.calculate_ratio(Color.WHITE, Color.BLACK), 21.0, 0.01)
	assert_almost_eq(ColorContrast.calculate_ratio(Color("808080"), Color("808080")), 1.0, 0.001)


func test_secondary_and_choice_buttons_are_outlined() -> void:
	for palette: ThemePalette in Settings.PALETTES.values():
		var theme: Theme = UiThemeBuilder.build(palette, load("res://assets/themes/base_theme.tres"))
		var button := Button.new()
		button.theme = theme
		add_child_autofree(button)
		for variation: StringName in [UiThemeBuilder.SECONDARY_BUTTON_TYPE, UiThemeBuilder.CHOICE_BUTTON_TYPE]:
			button.theme_type_variation = variation
			var normal_box := button.get_theme_stylebox(&"normal") as StyleBoxFlat
			assert_eq(normal_box.border_width_top, UiThemeBuilder.SECONDARY_BORDER_WIDTH, String(variation))
			assert_eq(normal_box.bg_color, palette.panel, String(variation))

