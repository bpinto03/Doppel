extends GutTest

const MIN_TILE_TEXT_CONTRAST: float = 4.5
const LEVEL_COUNT: int = 12


func test_every_palette_has_one_color_per_level() -> void:
	for palette_name: String in Settings.PALETTES:
		assert_eq(Settings.PALETTES[palette_name].tile_colors.size(), LEVEL_COUNT, palette_name)


func test_tile_text_is_readable_on_every_tile() -> void:
	for palette_name: String in Settings.PALETTES:
		var palette: ThemePalette = Settings.PALETTES[palette_name]
		for level: int in range(1, LEVEL_COUNT + 1):
			var contrast: float = _calculate_contrast(palette.tile_text, palette.get_tile_color(level))
			assert_gte(contrast, MIN_TILE_TEXT_CONTRAST, "%s level %d" % [palette_name, level])


## WCAG 2 contrast ratio.
func _calculate_contrast(first: Color, second: Color) -> float:
	var first_luminance: float = _calculate_relative_luminance(first)
	var second_luminance: float = _calculate_relative_luminance(second)
	return (maxf(first_luminance, second_luminance) + 0.05) / (minf(first_luminance, second_luminance) + 0.05)


func _calculate_relative_luminance(color: Color) -> float:
	var linear: Color = color.srgb_to_linear()
	return 0.2126 * linear.r + 0.7152 * linear.g + 0.0722 * linear.b
