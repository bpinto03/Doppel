extends GutTest

const SETTINGS_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/settings_screen.tscn")
const SETTINGS_ROWS_SCENE: PackedScene = preload("res://scenes/ui/settings_rows.tscn")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const TEST_SAVE_PATH: String = "user://test_settings_screen_save.cfg"
const TOGGLED_SETTINGS: Dictionary[String, StringName] = {
	"%SoundToggle": &"is_sound_enabled",
	"%MusicToggle": &"is_music_enabled",
	"%VibrationToggle": &"is_vibration_enabled",
	"%ScreenShakeToggle": &"is_screen_shake_enabled",
}

var _save := SaveFixture.new(TEST_SAVE_PATH)
var _screen: SettingsScreen
var _rows: SettingsRows


## Music off before the screen exists, so no test plays it.
func before_each() -> void:
	_save.use_test_save()
	Settings.is_music_enabled = false
	_screen = SETTINGS_SCREEN_SCENE.instantiate()
	add_child_autofree(_screen)
	_rows = _screen.get_node("%SettingsRows")


func after_each() -> void:
	AudioManager.stop_music()
	_save.restore_player_save()
	AudioManager.apply_settings()
	I18n.apply_language()


func test_each_toggle_switches_its_setting_and_keeps_it_after_a_reload() -> void:
	for toggle_path: String in TOGGLED_SETTINGS:
		var setting: StringName = TOGGLED_SETTINGS[toggle_path]
		var toggle: Button = _rows.get_node(toggle_path)
		var value_before: bool = Settings.get(setting)

		toggle.toggled.emit(not value_before)
		SaveManager.flush()
		SaveManager.load_save()

		assert_eq(Settings.get(setting), not value_before, String(setting))
		assert_eq(toggle.text, SettingsRows.ON_TEXT if not value_before else SettingsRows.OFF_TEXT, String(setting))


func test_choosing_a_language_applies_it_at_once_and_keeps_it() -> void:
	(_rows.get_node("%EnglishButton") as Button).pressed.emit()
	assert_eq(TranslationServer.get_locale(), "en")
	assert_true((_rows.get_node("%EnglishButton") as Button).button_pressed)

	(_rows.get_node("%FrenchButton") as Button).pressed.emit()
	SaveManager.flush()
	SaveManager.load_save()

	assert_eq(TranslationServer.get_locale(), "fr")
	assert_eq(Settings.language, "fr")
	assert_false((_rows.get_node("%EnglishButton") as Button).button_pressed)


func test_back_asks_to_leave() -> void:
	watch_signals(_screen)

	(_screen.get_node("%BackButton") as Button).pressed.emit()

	assert_signal_emitted(_screen, "back_requested")


func test_settings_open_from_home_and_back_returns_home() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	add_child_autofree(main)

	(main.get_current_screen() as HomeScreen).settings_requested.emit()
	assert_true(main.get_current_screen() is SettingsScreen)
	main.go_back()

	assert_true(main.get_current_screen() is HomeScreen)


func test_settings_screen_shows_every_group() -> void:
	for group_path: String in ["%Toggles", "%Language"]:
		assert_true((_rows.get_node(group_path) as Control).visible, group_path)


func test_rows_show_only_the_groups_asked_for() -> void:
	var toggles_only: SettingsRows = SETTINGS_ROWS_SCENE.instantiate()
	toggles_only.shown_groups = [SettingsRows.Group.TOGGLES]
	add_child_autofree(toggles_only)

	assert_true((toggles_only.get_node("%Toggles") as Control).visible)
	assert_false((toggles_only.get_node("%Language") as Control).visible)
