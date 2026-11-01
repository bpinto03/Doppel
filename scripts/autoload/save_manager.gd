extends Node

## Local save in a versioned ConfigFile. See docs/decisions/0002-save-format.md and 0005-save-writing.md.

const SETTINGS_SCRIPT: GDScript = preload("res://scripts/autoload/settings.gd")
const SAVE_VERSION: int = 2
const FIRST_SAVE_VERSION: int = 1
const SAVE_PATH: String = "user://save.cfg"
const TEMPORARY_SUFFIX: String = ".tmp"
const BACKUP_SUFFIX: String = ".bak"
const META_SECTION: String = "meta"
const VERSION_KEY: String = "version"

var save_path: String = SAVE_PATH
var _save_file := ConfigFile.new()
var _last_written_text: String
var _is_write_pending: bool


## The app may be killed without warning once inactive, so the waiting changes are written at once.
func _ready() -> void:
	AppLifecycle.deactivated.connect(flush)
	load_save()


## Reads the save, else its backup, else starts empty. Drops changes not yet written.
func load_save() -> void:
	_is_write_pending = false
	_save_file = _read_save_file(save_path)
	if _save_file == null:
		_save_file = _read_save_file(save_path + BACKUP_SUFFIX)
		if _save_file != null:
			push_warning("Save restored from its backup: %s" % save_path)
	if _save_file == null:
		_save_file = ConfigFile.new()
	_save_file.set_value(META_SECTION, VERSION_KEY, SAVE_VERSION)
	_last_written_text = _save_file.encode_to_text()


func get_value(section: String, key: String, default_value: Variant) -> Variant:
	return _save_file.get_value(section, key, default_value)


## Every key of the section, or an empty dictionary when the section is missing.
func get_section(section: String) -> Dictionary[String, Variant]:
	var values: Dictionary[String, Variant] = {}
	if _save_file.has_section(section):
		for key: String in _save_file.get_section_keys(section):
			values[key] = _save_file.get_value(section, key)
	return values


## Replaces the whole section, so no key from an older content is left behind.
func set_section(section: String, values: Dictionary[String, Variant]) -> void:
	if _save_file.has_section(section):
		_save_file.erase_section(section)
	for key: String in values:
		_save_file.set_value(section, key, values[key])
	_request_write()


func erase_section(section: String) -> void:
	if _save_file.has_section(section):
		_save_file.erase_section(section)
		_request_write()


## Written at the end of the frame, so several changes in a row make one write.
func set_value(section: String, key: String, value: Variant) -> void:
	_save_file.set_value(section, key, value)
	_request_write()


## Writes now the changes still waiting for the end of the frame, for when the app may be killed soon.
func flush() -> void:
	if _is_write_pending:
		_write_save()


func _request_write() -> void:
	if _is_write_pending:
		return
	_is_write_pending = true
	flush.call_deferred()


## A missing file is normal on the first launch; an unreadable one or one from a newer version is reported.
func _read_save_file(path: String) -> ConfigFile:
	if not FileAccess.file_exists(path):
		return null
	var save_file := ConfigFile.new()
	if save_file.load(path) != OK or save_file.get_sections().is_empty():
		push_warning("Save file unreadable, ignored: %s" % path)
		return null
	var version: Variant = save_file.get_value(META_SECTION, VERSION_KEY, FIRST_SAVE_VERSION)
	if not version is int or version > SAVE_VERSION:
		push_warning("Save file from an unknown version %s, ignored: %s" % [version, path])
		return null
	_migrate(save_file, version)
	return save_file


func _migrate(save_file: ConfigFile, from_version: int) -> void:
	if from_version < 2:
		save_file.set_value(SETTINGS_SCRIPT.SECTION, SETTINGS_SCRIPT.PALETTE_NAME_KEY, String(SETTINGS_SCRIPT.THEME_CATALOG.get_default_id()))


## The new save is written and read back in a temporary file before it replaces the current one,
## which becomes the backup: a kill at any point leaves a readable save or backup.
func _write_save() -> void:
	_is_write_pending = false
	var text: String = _save_file.encode_to_text()
	if text == _last_written_text:
		return
	var temporary_path: String = save_path + TEMPORARY_SUFFIX
	var error: Error = _save_file.save(temporary_path)
	if error == OK and not _has_text(temporary_path, text):
		error = ERR_FILE_CORRUPT
	if error == OK and FileAccess.file_exists(save_path):
		error = DirAccess.rename_absolute(save_path, save_path + BACKUP_SUFFIX)
	if error == OK:
		error = DirAccess.rename_absolute(temporary_path, save_path)
	if error != OK:
		push_error("Save failed: %s" % error_string(error))
		return
	_last_written_text = text


func _has_text(path: String, expected_text: String) -> bool:
	var written_file := ConfigFile.new()
	return written_file.load(path) == OK and written_file.encode_to_text() == expected_text
