extends GutTest

## The HUD above the board (score, record and pause only) and the tile, mirror and next previews under it.

const GAME_SCREEN_SCENE: PackedScene = preload("res://scenes/game/game_screen.tscn")
const BALANCING_CONFIG: BalancingConfig = preload("res://data/balancing.tres")
const TEST_SAVE_PATH: String = "user://test_game_hud_save.cfg"
const SEED: int = 1234
## Seven digits, shown without a thousands separator.
const LARGEST_SCORE: int = 9999999

var _save := SaveFixture.new(TEST_SAVE_PATH)
var _base_size := Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))


func before_each() -> void:
	_save.use_test_save()
	Settings.is_music_enabled = false
	Settings.is_sound_enabled = false


func after_each() -> void:
	AudioManager.stop_music()
	_save.restore_player_save()
	AudioManager.apply_settings()
	I18n.apply_language()


func test_hud_has_no_highest_tile() -> void:
	var game: GameScreen = await _add_game_screen()

	var game_over_panel: Control = game.get_node("%GameOverPanel")

	for label: Node in game.find_children("MaxTileValue", "", true, false):
		assert_true(game_over_panel.is_ancestor_of(label), "Only the game over overlay shows the highest tile")


## The narrowest screen is the base width: the stretch mode only widens the viewport.
func test_seven_digit_score_and_record_fit_their_panels_in_every_language() -> void:
	SaveManager.set_value(RecordBook.SECTION, RecordBook.BEST_SCORE_KEY, LARGEST_SCORE)
	for language: String in I18n.SUPPORTED_LANGUAGES:
		TranslationServer.set_locale(language)
		var game: GameScreen = await _add_game_screen(LARGEST_SCORE)
		var score_half: Control = game.get_node("%ScorePanel").get_parent()
		var record_half: Control = game.get_node("%RecordPanel")

		assert_eq((game.get_node("%ScoreLabel") as Label).text, str(LARGEST_SCORE))
		assert_lte((game.get_node("Margin") as Control).get_combined_minimum_size().x, _base_size.x, language)
		assert_almost_eq(score_half.size.x, record_half.size.x, 1.0, "%s: neither value widens its half" % language)


func test_preview_captions_fit_their_columns_in_every_language() -> void:
	for language: String in I18n.SUPPORTED_LANGUAGES:
		TranslationServer.set_locale(language)
		var game: GameScreen = await _add_game_screen()

		for swatch_name: String in ["%CurrentSwatch", "%ReflectionSwatch", "%NextSwatch"]:
			var caption: Label = game.get_node(swatch_name).get_parent().get_node("Caption")
			assert_lte(caption.get_minimum_size().x, GameScreen.PREVIEW_COLUMN_WIDTH, "%s %s" % [caption.text, language])


func test_mirror_preview_is_centered_on_the_screen_like_the_axis() -> void:
	var game: GameScreen = await _add_game_screen()

	assert_almost_eq((game.get_node("%ReflectionSwatch") as Control).get_global_rect().get_center().x, _base_size.x / 2.0, 1.0)


## Laid out at the base size, whatever the size of the test window.
func _add_game_screen(score: int = 0) -> GameScreen:
	var game: GameScreen = GAME_SCREEN_SCENE.instantiate()
	add_child_autofree(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	game.size = _base_size
	var session := GameSession.new(BALANCING_CONFIG, BalancingFixture.create_seeded_rng(SEED))
	session.score = score
	game.start_game(session, 0)
	await wait_process_frames(1)
	return game
