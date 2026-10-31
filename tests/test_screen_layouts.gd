extends GutTest

## Every screen and overlay keeps its content within the base width, in each supported language.

const HOME_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/home_screen.tscn")
const SETTINGS_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/settings_screen.tscn")
const GAME_SCREEN_SCENE: PackedScene = preload("res://scenes/game/game_screen.tscn")
const BALANCING_CONFIG: BalancingConfig = preload("res://data/balancing.tres")
const TEST_SAVE_PATH: String = "user://test_screen_layouts_save.cfg"
const PANEL_PATH: String = "Center/Panel"
const SEED: int = 1234
## A long score, so the game over values are as wide as they get in practice.
const LARGE_SCORE: int = 9999999

var _save := SaveFixture.new(TEST_SAVE_PATH)
var _viewport_width: float = ProjectSettings.get_setting("display/window/size/viewport_width")
var _base_size := Vector2(_viewport_width, ProjectSettings.get_setting("display/window/size/viewport_height"))


func before_each() -> void:
	_save.use_test_save()
	Settings.is_music_enabled = false
	Settings.is_sound_enabled = false


func after_each() -> void:
	AudioManager.stop_music()
	_save.restore_player_save()
	AudioManager.apply_settings()
	I18n.apply_language()


func test_screens_fit_the_base_width_in_every_language() -> void:
	for language: String in I18n.SUPPORTED_LANGUAGES:
		TranslationServer.set_locale(language)
		var home: HomeScreen = await _add_screen(HOME_SCREEN_SCENE)
		home.show_choices(HomeMenu.get_choices(true))
		var settings: Control = await _add_screen(SETTINGS_SCREEN_SCENE)
		var game: GameScreen = await _add_screen(GAME_SCREEN_SCENE)
		game.start_game(GameSession.new(BALANCING_CONFIG, BalancingFixture.create_seeded_rng(SEED)), 0)
		await wait_process_frames(1)

		for screen: Control in [home, settings, game]:
			assert_lte(_get_content_width(screen), _viewport_width, "%s in %s" % [screen.name, language])


func test_overlays_fit_their_panel_in_every_language() -> void:
	for language: String in I18n.SUPPORTED_LANGUAGES:
		TranslationServer.set_locale(language)
		var game: GameScreen = await _add_screen(GAME_SCREEN_SCENE)
		var session := GameSession.new(BALANCING_CONFIG, BalancingFixture.create_seeded_rng(SEED))
		session.score = LARGE_SCORE
		session.highest_level_reached = BALANCING_CONFIG.max_tile_level
		game.start_game(session, 1)
		var game_over_panel: GameOverPanel = game.get_node("%GameOverPanel")
		game_over_panel.show_summary(GameOverSummary.new(session, 1, LARGE_SCORE))
		await wait_process_frames(1)

		var panel: Control = game_over_panel.get_node(PANEL_PATH)
		assert_lte(panel.get_combined_minimum_size().x, panel.custom_minimum_size.x, "%s in %s" % [game_over_panel.name, language])


## The panel width is set from the screen; content wider than it would push the texts past it.
func test_both_pause_pages_fit_the_safe_area_at_the_base_size_in_every_language() -> void:
	for language: String in I18n.SUPPORTED_LANGUAGES:
		TranslationServer.set_locale(language)
		var game: GameScreen = await _add_screen(GAME_SCREEN_SCENE)
		game.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		game.size = _base_size
		game.start_game(GameSession.new(BALANCING_CONFIG, BalancingFixture.create_seeded_rng(SEED)), 0)
		game.open_pause()
		var pause_panel: PausePanel = game.get_node("%PausePanel")
		for page: String in ["main", "settings"]:
			if page == "main":
				pause_panel.show_main_page()
			else:
				pause_panel.show_settings_page()
			await wait_process_frames(2)

			var panel: Control = pause_panel.get_node("%Panel")
			var context: String = "%s page in %s" % [page, language]
			assert_lte(panel.get_minimum_size().x, panel.custom_minimum_size.x, context)
			assert_true(_get_safe_rect(pause_panel.get_node("%Margin")).encloses(panel.get_global_rect()), context)


func _get_safe_rect(margin: MarginContainer) -> Rect2:
	var top_left := Vector2(margin.get_theme_constant(&"margin_left"), margin.get_theme_constant(&"margin_top"))
	var bottom_right := Vector2(margin.get_theme_constant(&"margin_right"), margin.get_theme_constant(&"margin_bottom"))
	return Rect2(margin.global_position + top_left, margin.size - top_left - bottom_right)


func _add_screen(scene: PackedScene) -> Control:
	var screen: Control = scene.instantiate()
	add_child_autofree(screen)
	await wait_process_frames(1)
	return screen


## The root Control does not report its children's minimum size, so the margin container is measured.
func _get_content_width(screen: Control) -> float:
	return (screen.get_node("Margin") as Control).get_combined_minimum_size().x
