extends Node

## Player settings, stored through SaveManager.

signal changed
signal palette_changed

const SECTION: String = "settings"
const FOLLOW_DEVICE_LANGUAGE: String = ""
const THEME_CATALOG: ThemeCatalog = preload("res://data/theme_catalog.tres")
const PALETTE_NAME_KEY: String = "palette_name"
const DEFAULT_BUS_VOLUME: float = 1.0

var _theme_shop := ThemeShop.new(THEME_CATALOG)

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


## The id of the equipped theme in THEME_CATALOG. A saved id that is unknown or not owned reads as the default theme.
var palette_name: String:
	get:
		var saved_id: String = str(SaveManager.get_value(SECTION, PALETTE_NAME_KEY, THEME_CATALOG.get_default_id()))
		return String(_theme_shop.resolve_equipped_id(StringName(saved_id)))
	set(value):
		_store(PALETTE_NAME_KEY, value)
		palette_changed.emit()


## Linear volume of an audio bus, from 0 (muted) to 1.
func get_bus_volume(bus_name: StringName) -> float:
	return SaveManager.get_value(SECTION, _get_bus_volume_key(bus_name), DEFAULT_BUS_VOLUME)


func set_bus_volume(bus_name: StringName, volume: float) -> void:
	_store(_get_bus_volume_key(bus_name), clampf(volume, 0.0, 1.0))


func get_palette() -> ThemePalette:
	return THEME_CATALOG.find_entry(StringName(palette_name)).palette


func _get_bus_volume_key(bus_name: StringName) -> String:
	return "volume_%s" % String(bus_name).to_lower()


func _store(key: String, value: Variant) -> void:
	SaveManager.set_value(SECTION, key, value)
	changed.emit()
