class_name SettingsRows
extends VBoxContainer

## Every setting row, defined once: the sound, music, vibration and screen shake toggles, the language and the theme.
## Each change is saved at once by Settings. A screen shows only the groups it needs.

enum Group { TOGGLES, LANGUAGE, THEME }

const ON_TEXT: String = "UI_ON"
const OFF_TEXT: String = "UI_OFF"

@export var shown_groups: Array[Group] = [Group.TOGGLES, Group.LANGUAGE, Group.THEME]

## Settings property switched by each toggle.
var _toggled_settings: Dictionary[Button, StringName] = {}
## Language code chosen by each language button.
var _language_buttons: Dictionary[String, Button] = {}
## Palette name chosen by each theme button.
var _theme_buttons: Dictionary[String, Button] = {}


func _ready() -> void:
	var groups: Dictionary[Group, Control] = {Group.TOGGLES: %Toggles, Group.LANGUAGE: %Language, Group.THEME: %Theme}
	for group: Group in groups:
		groups[group].visible = shown_groups.has(group)
	_toggled_settings = {
		%SoundToggle: &"is_sound_enabled",
		%MusicToggle: &"is_music_enabled",
		%VibrationToggle: &"is_vibration_enabled",
		%ScreenShakeToggle: &"is_screen_shake_enabled",
	}
	_language_buttons = {"fr": %FrenchButton, "en": %EnglishButton}
	_theme_buttons = {"paper": %PaperButton, "night": %NightButton}
	for toggle: Button in _toggled_settings:
		toggle.toggled.connect(_on_setting_toggled.bind(toggle))
	for language: String in _language_buttons:
		_language_buttons[language].pressed.connect(_on_language_chosen.bind(language))
	for palette_name: String in _theme_buttons:
		_theme_buttons[palette_name].pressed.connect(_on_theme_chosen.bind(palette_name))
	_show_settings()


func _on_setting_toggled(is_on: bool, toggle: Button) -> void:
	Settings.set(_toggled_settings[toggle], is_on)
	_show_settings()


func _on_language_chosen(language: String) -> void:
	Settings.language = language
	_show_settings()


func _on_theme_chosen(palette_name: String) -> void:
	Settings.palette_name = palette_name
	_show_settings()


## Without signals, so showing a value never writes it back.
func _show_settings() -> void:
	for toggle: Button in _toggled_settings:
		var is_on: bool = Settings.get(_toggled_settings[toggle])
		toggle.set_pressed_no_signal(is_on)
		toggle.text = ON_TEXT if is_on else OFF_TEXT
	var shown_language: String = I18n.resolve_language(Settings.language, OS.get_locale_language())
	for language: String in _language_buttons:
		_language_buttons[language].set_pressed_no_signal(language == shown_language)
	for palette_name: String in _theme_buttons:
		_theme_buttons[palette_name].set_pressed_no_signal(palette_name == Settings.palette_name)
