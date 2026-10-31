extends GutTest

const HOME_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/home_screen.tscn")
## Wider than half of any phone screen, as a long translation could be.
const LONG_TEXT_LENGTH: int = 80
## Room every button keeps beyond its minimum width side by side, so a slightly longer translation still fits.
const MIN_SPARE_WIDTH: float = 30.0
const BUTTON_PATHS: Array[String] = ["%PlayButton", "%ContinueButton", "%TutorialButton", "%SettingsButton"]

var _home: HomeScreen
var _base_size := Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))


func before_each() -> void:
	_home = await _add_home_screen()


func after_each() -> void:
	I18n.apply_language()


func test_short_texts_put_play_left_of_continue() -> void:
	_home.show_choices(HomeMenu.get_choices(true))

	assert_false(_home.is_stacked())
	assert_eq(_get_button_order(), ["PlayButton", "ContinueButton"])


func test_texts_too_wide_for_half_the_screen_stack_continue_above_play() -> void:
	(_home.get_node("%PlayButton") as Button).text = "W".repeat(LONG_TEXT_LENGTH)

	_home.show_choices(HomeMenu.get_choices(true))

	assert_true(_home.is_stacked())
	assert_eq(_get_button_order(), ["ContinueButton", "PlayButton"])


func test_play_alone_hides_continue() -> void:
	_home.show_choices(HomeMenu.get_choices(false))

	assert_false(_home.is_choice_shown(HomeMenu.Choice.CONTINUE))
	assert_false(_home.is_stacked())


## The narrowest screen is the base width: the stretch mode only widens the viewport.
func test_both_rows_fit_side_by_side_with_room_to_spare_in_every_language() -> void:
	for language: String in I18n.SUPPORTED_LANGUAGES:
		TranslationServer.set_locale(language)
		var home: HomeScreen = await _add_home_screen()
		home.show_choices(HomeMenu.get_choices(true))
		await wait_process_frames(1)

		assert_false(home.is_stacked(), language)
		assert_false((home.get_node("%SecondaryButtons") as BoxContainer).vertical, language)
		for button_path: String in BUTTON_PATHS:
			var button: Button = home.get_node(button_path)
			var spare_width: float = button.size.x - button.get_combined_minimum_size().x
			assert_gte(spare_width, MIN_SPARE_WIDTH, "%s %s" % [tr(button.text), language])


func test_every_button_plays_the_click() -> void:
	_home.show_choices(HomeMenu.get_choices(true))
	var click: AudioStream = HomeScreen.AUDIO_CONFIG.ui_click.stream
	for button_path: String in BUTTON_PATHS:
		_stop_effects()

		(_home.get_node(button_path) as Button).pressed.emit()

		assert_true(_is_playing(click), button_path)


func _add_home_screen() -> HomeScreen:
	var home: HomeScreen = HOME_SCREEN_SCENE.instantiate()
	add_child_autofree(home)
	home.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	home.size = _base_size
	await wait_process_frames(1)
	return home


func _stop_effects() -> void:
	for player: Node in AudioManager.get_children():
		if player is AudioStreamPlayer:
			(player as AudioStreamPlayer).stop()


func _is_playing(stream: AudioStream) -> bool:
	for player: Node in AudioManager.get_children():
		if player is AudioStreamPlayer and (player as AudioStreamPlayer).stream == stream and (player as AudioStreamPlayer).playing:
			return true
	return false


func _get_button_order() -> Array[String]:
	var names: Array[String] = []
	for button: Node in _home.get_node("%ChoiceButtons").get_children():
		names.append(button.name)
	return names
