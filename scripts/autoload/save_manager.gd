extends Node

## Local save in a versioned ConfigFile. See docs/decisions/0002-save-format.md.

const SETTINGS_SCRIPT: GDScript = preload("res://scripts/autoload/settings.gd")
const SAVE_VERSION: int = 2
const FIRST_SAVE_VERSION: int = 1
const SAVE_PATH: String = "user://save.cfg"
const META_SECTION: String = "meta"
const VERSION_KEY: String = "version"

var save_path: String = SAVE_PATH
var _save_file := ConfigFile.new()


func _ready() -> void:
	load_save()


## A missing or unreadable save starts empty; an older one is migrated.
func load_save() -> void:
	_save_file = ConfigFile.new()
	if _save_file.load(save_path) == OK:
		_migrate(_save_file.get_value(META_SECTION, VERSION_KEY, FIRST_SAVE_VERSION))
	else:
		_save_file = ConfigFile.new()
	_save_file.set_value(META_SECTION, VERSION_KEY, SAVE_VERSION)


func get_value(section: String, key: String, default_value: Variant) -> Variant:
	return _save_file.get_value(section, key, default_value)


func set_value(section: String, key: String, value: Variant) -> void:
	_save_file.set_value(section, key, value)
	_write_save()


func _migrate(from_version: int) -> void:
	if from_version < 2:
		_save_file.set_value(SETTINGS_SCRIPT.SECTION, SETTINGS_SCRIPT.PALETTE_NAME_KEY, SETTINGS_SCRIPT.DEFAULT_PALETTE_NAME)


## Writes to a temporary file first, so a kill during the write never corrupts the existing save.
func _write_save() -> void:
	var temporary_path: String = save_path + ".tmp"
	var error: Error = _save_file.save(temporary_path)
	if error == OK:
		error = DirAccess.rename_absolute(temporary_path, save_path)
	if error != OK:
		push_error("Save failed: %s" % error_string(error))
