extends GutTest

## Night and Neon keep neighbor levels apart for every vision, and Neon its repeated hues in normal vision (see 0003).
## Paper is left out on purpose: its pastel tiles are told apart by their value only.

const MIN_GRAY_GAP: float = 10.0
const MIN_COLOR_DIFFERENCE: float = 12.0
const CHECKED_THEME_IDS: Array[StringName] = [&"night", &"neon"]
## Levels whose Neon colors share a hue: 2 and 512, 4 and 1024, 128 and 2048, 64 and 256.
const NEON_REPEATED_HUE_LEVELS: Array[Vector2i] = [Vector2i(1, 9), Vector2i(2, 10), Vector2i(7, 11), Vector2i(6, 8)]
## Sharma, Wu and Dalal, test pair 1.
const REFERENCE_FIRST_LAB := Vector3(50.0, 2.6772, -79.7751)
const REFERENCE_SECOND_LAB := Vector3(50.0, 0.0, -82.7485)
const REFERENCE_DIFFERENCE: float = 2.0425


func test_ciede2000_matches_the_reference_pair() -> void:
	assert_almost_eq(ColorVisionFixture.calculate_ciede2000(REFERENCE_FIRST_LAB, REFERENCE_SECOND_LAB), REFERENCE_DIFFERENCE, 0.0001)


func test_neighbor_levels_differ_in_gray_and_in_every_vision() -> void:
	for theme_id: StringName in CHECKED_THEME_IDS:
		var colors: Array[Color] = Settings.THEME_CATALOG.find_entry(theme_id).palette.tile_colors
		for level: int in range(1, colors.size()):
			var lower: Color = colors[level - 1]
			var upper: Color = colors[level]
			var context: String = "%s levels %d and %d" % [theme_id, level, level + 1]
			assert_gte(ColorVisionFixture.calculate_gray_gap(lower, upper), MIN_GRAY_GAP, context)
			for vision: ColorVisionFixture.Vision in ColorVisionFixture.Vision.values():
				assert_gte(ColorVisionFixture.calculate_color_difference(lower, upper, vision), MIN_COLOR_DIFFERENCE, "%s, vision %d" % [context, vision])


func test_neon_repeated_hues_stay_apart_in_normal_vision() -> void:
	var colors: Array[Color] = Settings.THEME_CATALOG.find_entry(&"neon").palette.tile_colors
	for levels: Vector2i in NEON_REPEATED_HUE_LEVELS:
		var difference: float = ColorVisionFixture.calculate_color_difference(colors[levels.x - 1], colors[levels.y - 1], ColorVisionFixture.Vision.NORMAL)
		assert_gte(difference, MIN_COLOR_DIFFERENCE, "levels %d and %d" % [levels.x, levels.y])
