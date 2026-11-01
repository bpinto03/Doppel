extends GutTest

## Grain, hollow cells and engraving are optional palette features: only Wood sets them (see 0009).

const BASE_THEME: Theme = preload("res://assets/themes/base_theme.tres")
const GAME_SCREEN_SCENE: PackedScene = preload("res://scenes/game/game_screen.tscn")
const OVERLAY_TOOL: GDScript = preload("res://tools/textures/build_grain_overlay.gd")
const TEST_SAVE_PATH: String = "user://test_surface_grain_save.cfg"
const TEXTURE_SIZE := Vector2(1024.0, 1024.0)
const DEFAULT_THEME_IDS: Array[StringName] = [&"paper", &"night", &"neon"]

var _save := SaveFixture.new(TEST_SAVE_PATH)


func before_each() -> void:
	_save.use_test_save()
	Settings.is_music_enabled = false
	Settings.is_sound_enabled = false


func after_each() -> void:
	AudioManager.stop_music()
	_save.restore_player_save()
	AudioManager.apply_settings()


func test_only_wood_sets_the_optional_wood_features() -> void:
	for theme_id: StringName in DEFAULT_THEME_IDS:
		var palette: ThemePalette = _get_palette(theme_id)
		assert_false(palette.has_surface_grain() or palette.has_tile_grain(), String(theme_id))
		assert_false(palette.has_hollow_cells() or palette.has_engraved_hud_icons() or palette.has_engraved_titles(), String(theme_id))
	var wood: ThemePalette = _get_palette(&"wood")
	assert_true(wood.has_surface_grain() and wood.has_tile_grain() and wood.has_hollow_cells(), "wood")
	assert_true(wood.has_engraved_hud_icons() and wood.has_engraved_titles(), "wood")


func test_grain_wraps_opaque_boxes_only() -> void:
	var theme: Theme = UiThemeBuilder.build(_get_palette(&"wood"), BASE_THEME)

	assert_is(theme.get_stylebox(&"panel", UiThemeBuilder.SHOP_CARD_TYPE), GrainStyleBox)
	assert_is(theme.get_stylebox(&"panel", UiThemeBuilder.MODAL_SCRIM_TYPE), StyleBoxFlat, "Translucent scrim")
	assert_is(theme.get_stylebox(&"panel", UiThemeBuilder.SHOP_PREVIEW_RING_TYPE), StyleBoxFlat, "Ring without fill")


func test_themes_without_grain_keep_flat_boxes() -> void:
	for theme_id: StringName in DEFAULT_THEME_IDS:
		var theme: Theme = UiThemeBuilder.build(_get_palette(theme_id), BASE_THEME)
		for type: StringName in theme.get_type_list():
			for name: StringName in theme.get_stylebox_list(type):
				assert_false(theme.get_stylebox(name, type) is GrainStyleBox, "%s %s %s" % [theme_id, type, name])


## Layouts must not move: the wrapper keeps the margins of the box it draws.
func test_grained_box_keeps_the_margins_of_its_box() -> void:
	var box := StyleBoxFlat.new()
	box.set_border_width_all(3)
	box.content_margin_left = 20.0
	box.content_margin_top = 12.0

	var grained := GrainStyleBox.new(box, null, 0.5)

	assert_eq(grained.get_minimum_size(), box.get_minimum_size())


func test_grain_outline_follows_the_capped_corners() -> void:
	var rect := Rect2(10.0, 20.0, 100.0, 40.0)

	var points: PackedVector2Array = SurfaceGrain._build_rounded_rect(rect, Vector4(8.0, 8.0, 50.0, 0.0))

	for point: Vector2 in points:
		assert_true(rect.grow(0.001).has_point(point), str(point))
	assert_true(points.has(Vector2(rect.position.x, rect.end.y)), "Square bottom left corner kept for a radius of 0")


func test_grain_reads_inside_the_overlay_even_on_a_larger_surface() -> void:
	for surface: Rect2 in [Rect2(300.0, 900.0, 120.0, 120.0), Rect2(0.0, 0.0, 1500.0, 900.0)]:
		var points: PackedVector2Array = SurfaceGrain._build_rounded_rect(surface, Vector4.ONE * 10.0)
		for uv: Vector2 in SurfaceGrain._map_to_texture(points, surface, TEXTURE_SIZE):
			assert_true(Rect2(Vector2.ZERO, Vector2.ONE).grow(0.001).has_point(uv), "%s %s" % [surface, uv])


func test_overlay_darkens_below_the_mean_and_lightens_above() -> void:
	var grain := Image.create(3, 1, false, Image.FORMAT_L8)
	grain.set_pixel(0, 0, Color(0.4, 0.4, 0.4))
	grain.set_pixel(1, 0, Color(0.5, 0.5, 0.5))
	grain.set_pixel(2, 0, Color(0.6, 0.6, 0.6))

	var overlay: Image = OVERLAY_TOOL.build_overlay(grain)

	assert_eq(Color(overlay.get_pixel(0, 0), 1.0), Color.BLACK)
	assert_almost_eq(overlay.get_pixel(1, 0).a, 0.0, 0.01)
	assert_eq(Color(overlay.get_pixel(2, 0), 1.0), Color.WHITE)
	assert_almost_eq(overlay.get_pixel(0, 0).a, overlay.get_pixel(2, 0).a, 0.01)


func test_engraved_titles_drop_a_light_lip() -> void:
	var wood: ThemePalette = _get_palette(&"wood")
	var theme: Theme = UiThemeBuilder.build(wood, BASE_THEME)

	for type: StringName in [UiThemeBuilder.HOME_TITLE_TYPE, UiThemeBuilder.MODAL_TITLE_TYPE]:
		assert_eq(theme.get_color(&"font_shadow_color", type), wood.title_engraving_highlight, type)
		assert_eq(theme.get_constant(&"shadow_offset_y", type), UiThemeBuilder.TITLE_ENGRAVING_OFFSET, type)
		assert_eq(theme.get_constant(&"shadow_outline_size", type), 0, type)


func test_hud_icons_are_engraved_only_in_wood() -> void:
	for theme_id: StringName in [&"paper", &"wood"]:
		_own(theme_id)
		var game: GameScreen = GAME_SCREEN_SCENE.instantiate()
		add_child_autofree(game)

		var icon_material: Material = (game.get_node("%ScoreIcon") as TextureRect).material

		if theme_id == &"wood":
			assert_not_null(icon_material, String(theme_id))
		else:
			assert_null(icon_material, String(theme_id))


func _own(theme_id: StringName) -> void:
	var price: int = Settings.THEME_CATALOG.find_entry(theme_id).price
	if price > 0:
		CoinWallet.add_coins(price)
		ThemeShop.new(Settings.THEME_CATALOG).try_buy(theme_id)
	Settings.palette_name = String(theme_id)


func _get_palette(theme_id: StringName) -> ThemePalette:
	return Settings.THEME_CATALOG.find_entry(theme_id).palette
