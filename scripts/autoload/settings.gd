extends Node

## Player settings, stored through SaveManager.

signal changed
signal palette_changed

const SECTION: String = "settings"
const FOLLOW_DEVICE_LANGUAGE: String = ""
const PALETTES: Dictionary[String, ThemePalette] = {
	"paper": preload("res://data/palette_paper.tres"),
	"night": preload("res://data/palette_night.tres"),
}
const DEFAULT_PALETTE_NAME: String = "paper"
const PALETTE_NAME_KEY: String = "palette_name"

var is_sound_enabled: bool:
	get:
		return SaveManager.get_value(SECTION, "is_sound_enabled", true)
	set(value):
		_store("is_sound_enabled", value)

var is_music_enabled: bool:
	get:
		return SaveManager.get_value(SECTION, "is_music_enabled", true)
	set(value):
		_store("is_music_enabled", value)

var is_vibration_enabled: bool:
	get:
		return SaveManager.get_value(SECTION, "is_vibration_enabled", true)
	set(value):
		_store("is_vibration_enabled", value)

## A supported language code, or FOLLOW_DEVICE_LANGUAGE.
var language: String:
	get:
		return SaveManager.get_value(SECTION, "language", FOLLOW_DEVICE_LANGUAGE)
	set(value):
		_store("language", value)


## A key of PALETTES.
var palette_name: String:
	get:
		return SaveManager.get_value(SECTION, PALETTE_NAME_KEY, DEFAULT_PALETTE_NAME)
	set(value):
		_store(PALETTE_NAME_KEY, value)
		palette_changed.emit()


func get_palette() -> ThemePalette:
	return PALETTES.get(palette_name, PALETTES[DEFAULT_PALETTE_NAME])


func _store(key: String, value: Variant) -> void:
	SaveManager.set_value(SECTION, key, value)
	changed.emit()
