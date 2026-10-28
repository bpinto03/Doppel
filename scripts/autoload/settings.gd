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
const DEFAULT_BUS_VOLUME: float = 1.0

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

var is_screen_shake_enabled: bool:
	get:
		return SaveManager.get_value(SECTION, "is_screen_shake_enabled", true)
	set(value):
		_store("is_screen_shake_enabled", value)

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


## Linear volume of an audio bus, from 0 (muted) to 1.
func get_bus_volume(bus_name: StringName) -> float:
	return SaveManager.get_value(SECTION, _get_bus_volume_key(bus_name), DEFAULT_BUS_VOLUME)


func set_bus_volume(bus_name: StringName, volume: float) -> void:
	_store(_get_bus_volume_key(bus_name), clampf(volume, 0.0, 1.0))


func get_palette() -> ThemePalette:
	return PALETTES.get(palette_name, PALETTES[DEFAULT_PALETTE_NAME])


func _get_bus_volume_key(bus_name: StringName) -> String:
	return "volume_%s" % String(bus_name).to_lower()


func _store(key: String, value: Variant) -> void:
	SaveManager.set_value(SECTION, key, value)
	changed.emit()
