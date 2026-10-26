extends Node

## Player settings, stored through SaveManager.

signal changed

const SECTION: String = "settings"
const FOLLOW_DEVICE_LANGUAGE: String = ""

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


func _store(key: String, value: Variant) -> void:
	SaveManager.set_value(SECTION, key, value)
	changed.emit()
