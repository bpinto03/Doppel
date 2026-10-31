extends GutTest

## The tutorial panel at the base size, in every language: one height through its states and steps,
## every text whole, inside the safe area and below the board.

const GAME_SCREEN_SCENE: PackedScene = preload("res://scenes/game/game_screen.tscn")
const TEST_SAVE_PATH: String = "user://test_tutorial_panel_save.cfg"

var _save := SaveFixture.new(TEST_SAVE_PATH)
var _base_size := Vector2(
	ProjectSettings.get_setting("display/window/size/viewport_width"),
	ProjectSettings.get_setting("display/window/size/viewport_height"))


func before_each() -> void:
	_save.use_test_save()
	Settings.is_music_enabled = false
	Settings.is_sound_enabled = false


func after_each() -> void:
	AudioManager.stop_music()
	_save.restore_player_save()
	AudioManager.apply_settings()
	I18n.apply_language()


func test_panel_keeps_one_height_and_shows_every_text_whole_in_every_language() -> void:
	var steps: Array[TutorialStep] = TutorialScenarios.create_steps()
	for language: String in I18n.SUPPORTED_LANGUAGES:
		TranslationServer.set_locale(language)
		var game: GameScreen = await _add_game_screen_in_tutorial()
		var panel: TutorialPanel = game.get_node("%TutorialPanel")
		var first_height: float = panel.size.y
		for step_index: int in steps.size():
			var step: TutorialStep = steps[step_index]
			panel.show_instruction(step.instruction_key)
			await _assert_panel_layout(game, first_height, "instruction %d in %s" % [step_index + 1, language])
			panel.show_explanation(step.explanation_key, step_index == steps.size() - 1)
			await _assert_panel_layout(game, first_height, "explanation %d in %s" % [step_index + 1, language])


func test_last_explanation_shows_done_without_skip() -> void:
	var game: GameScreen = await _add_game_screen_in_tutorial()
	var panel: TutorialPanel = game.get_node("%TutorialPanel")
	var last_step: TutorialStep = TutorialScenarios.create_steps().back()

	panel.show_explanation(last_step.explanation_key, true)

	assert_false((panel.get_node("%SkipButton") as Button).visible)
	assert_eq((panel.get_node("%NextButton") as Button).text, tr(&"TUTORIAL_DONE"))
	assert_true(panel.is_waiting_for_next())


func _add_game_screen_in_tutorial() -> GameScreen:
	var game: GameScreen = GAME_SCREEN_SCENE.instantiate()
	add_child_autofree(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	game.size = _base_size
	game.start_tutorial()
	await wait_process_frames(2)
	return game


func _assert_panel_layout(game: GameScreen, expected_height: float, context: String) -> void:
	await wait_process_frames(2)
	var panel: TutorialPanel = game.get_node("%TutorialPanel")
	var message_label: Label = panel.get_node("%MessageLabel")
	assert_eq(panel.size.y, expected_height, "Height, " + context)
	assert_eq(message_label.get_visible_line_count(), message_label.get_line_count(), "Message, " + context)
	assert_lte(panel.get_combined_minimum_size().x, panel.size.x, "Width, " + context)
	for button: Button in [panel.get_node("%SkipButton"), panel.get_node("%NextButton")]:
		if button.visible:
			assert_lte(button.get_minimum_size().x, button.size.x, "%s, %s" % [button.name, context])
	assert_true(_get_safe_rect(game.get_node("Margin")).encloses(panel.get_global_rect()), "Safe area, " + context)
	assert_false(panel.get_global_rect().intersects((game.get_node("%BoardView") as Control).get_global_rect()), "Board, " + context)


func _get_safe_rect(margin: MarginContainer) -> Rect2:
	var top_left := Vector2(margin.get_theme_constant(&"margin_left"), margin.get_theme_constant(&"margin_top"))
	var bottom_right := Vector2(margin.get_theme_constant(&"margin_right"), margin.get_theme_constant(&"margin_bottom"))
	return Rect2(margin.global_position + top_left, margin.size - top_left - bottom_right)
