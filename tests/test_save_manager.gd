extends GutTest

const SAVE_MANAGER_SCRIPT: GDScript = preload("res://scripts/autoload/save_manager.gd")
const SETTINGS_SCRIPT: GDScript = preload("res://scripts/autoload/settings.gd")
const TEST_SAVE_PATH: String = "user://test_save.cfg"
const BACKUP_PATH: String = TEST_SAVE_PATH + SAVE_MANAGER_SCRIPT.BACKUP_SUFFIX
const TEMPORARY_PATH: String = TEST_SAVE_PATH + SAVE_MANAGER_SCRIPT.TEMPORARY_SUFFIX
## Above 2^53, so a float would lose it: random generator states reach such values.
const LARGE_INTEGER: int = 9007199254740993


func before_each() -> void:
	SaveFixture.delete_save_files(TEST_SAVE_PATH)


func after_each() -> void:
	SaveFixture.delete_save_files(TEST_SAVE_PATH)


func test_missing_save_starts_empty_with_current_version() -> void:
	var save_manager: Node = _create_save_manager()

	assert_eq(save_manager.get_value("record", "best_score", 0), 0)
	assert_eq(save_manager.get_value(SAVE_MANAGER_SCRIPT.META_SECTION, SAVE_MANAGER_SCRIPT.VERSION_KEY, 0), SAVE_MANAGER_SCRIPT.SAVE_VERSION)


func test_saved_value_survives_a_reload() -> void:
	_save_value("record", "best_score", 1234)

	assert_eq(_create_save_manager().get_value("record", "best_score", 0), 1234)


func test_large_integers_and_packed_arrays_survive_a_reload() -> void:
	_save_value("current_game", "rng_state", LARGE_INTEGER)
	_save_value("current_game", "board_levels", PackedInt32Array([0, 3, 12]))

	var reloaded_manager: Node = _create_save_manager()

	assert_eq(reloaded_manager.get_value("current_game", "rng_state", 0), LARGE_INTEGER)
	assert_eq(reloaded_manager.get_value("current_game", "board_levels", PackedInt32Array()), PackedInt32Array([0, 3, 12]))


func test_saved_file_records_the_version() -> void:
	_save_value("record", "best_score", 1)

	var save_file := ConfigFile.new()
	save_file.load(TEST_SAVE_PATH)

	assert_eq(save_file.get_value(SAVE_MANAGER_SCRIPT.META_SECTION, SAVE_MANAGER_SCRIPT.VERSION_KEY, 0), SAVE_MANAGER_SCRIPT.SAVE_VERSION)


func test_changes_wait_for_the_end_of_the_frame_then_make_one_write() -> void:
	var save_manager: Node = _create_save_manager()
	save_manager.set_value("record", "best_score", 1)
	save_manager.set_value("record", "best_score", 2)

	assert_false(FileAccess.file_exists(TEST_SAVE_PATH))
	await wait_process_frames(1)

	assert_true(FileAccess.file_exists(TEST_SAVE_PATH))
	assert_false(FileAccess.file_exists(BACKUP_PATH), "A second write would have kept the first as a backup")
	assert_eq(_create_save_manager().get_value("record", "best_score", 0), 2)


func test_unchanged_save_is_not_written_again() -> void:
	var save_manager: Node = _save_value("record", "best_score", 5)

	save_manager.set_value("record", "best_score", 5)
	save_manager.flush()

	assert_false(FileAccess.file_exists(BACKUP_PATH))


func test_write_keeps_the_previous_save_as_backup_and_no_temporary_file() -> void:
	var save_manager: Node = _save_value("record", "best_score", 1)

	save_manager.set_value("record", "best_score", 2)
	save_manager.flush()

	assert_false(FileAccess.file_exists(TEMPORARY_PATH))
	var backup_file := ConfigFile.new()
	backup_file.load(BACKUP_PATH)
	assert_eq(backup_file.get_value("record", "best_score", 0), 1)


func test_unreadable_save_starts_empty() -> void:
	_write_text(TEST_SAVE_PATH, "[record\nbest_score = ")

	var save_manager: Node = _create_save_manager()

	assert_engine_error("ConfigFile parse error")
	assert_eq(save_manager.get_value("record", "best_score", 0), 0)


func test_empty_save_starts_empty() -> void:
	_write_text(TEST_SAVE_PATH, "")

	var save_manager: Node = _create_save_manager()

	assert_eq(save_manager.get_value("record", "best_score", 0), 0)
	assert_eq(save_manager.get_value(SAVE_MANAGER_SCRIPT.META_SECTION, SAVE_MANAGER_SCRIPT.VERSION_KEY, 0), SAVE_MANAGER_SCRIPT.SAVE_VERSION)


func test_unreadable_save_falls_back_to_its_backup() -> void:
	var save_manager: Node = _save_value("record", "best_score", 1)
	save_manager.set_value("record", "best_score", 2)
	save_manager.flush()
	_write_text(TEST_SAVE_PATH, "[record\nbest_score = ")

	var reloaded_manager: Node = _create_save_manager()

	assert_engine_error("ConfigFile parse error")
	assert_eq(reloaded_manager.get_value("record", "best_score", 0), 1)


## A kill between the two renames leaves only the backup.
func test_missing_save_with_a_backup_restores_the_backup() -> void:
	var save_manager: Node = _save_value("record", "best_score", 1)
	save_manager.set_value("record", "best_score", 2)
	save_manager.flush()
	DirAccess.remove_absolute(TEST_SAVE_PATH)

	assert_eq(_create_save_manager().get_value("record", "best_score", 0), 1)


func test_save_from_an_unknown_version_starts_empty() -> void:
	var newer_file := ConfigFile.new()
	newer_file.set_value(SAVE_MANAGER_SCRIPT.META_SECTION, SAVE_MANAGER_SCRIPT.VERSION_KEY, SAVE_MANAGER_SCRIPT.SAVE_VERSION + 1)
	newer_file.set_value("record", "best_score", 512)
	newer_file.save(TEST_SAVE_PATH)

	var save_manager: Node = _create_save_manager()

	assert_eq(save_manager.get_value("record", "best_score", 0), 0)
	assert_eq(save_manager.get_value(SAVE_MANAGER_SCRIPT.META_SECTION, SAVE_MANAGER_SCRIPT.VERSION_KEY, 0), SAVE_MANAGER_SCRIPT.SAVE_VERSION)


func test_first_version_save_is_migrated_with_the_default_palette() -> void:
	var first_version_file := ConfigFile.new()
	first_version_file.set_value(SAVE_MANAGER_SCRIPT.META_SECTION, SAVE_MANAGER_SCRIPT.VERSION_KEY, SAVE_MANAGER_SCRIPT.FIRST_SAVE_VERSION)
	first_version_file.set_value("record", "best_score", 512)
	first_version_file.set_value(SETTINGS_SCRIPT.SECTION, "is_vibration_enabled", false)
	first_version_file.save(TEST_SAVE_PATH)

	var save_manager: Node = _create_save_manager()

	assert_eq(save_manager.get_value(SETTINGS_SCRIPT.SECTION, SETTINGS_SCRIPT.PALETTE_NAME_KEY, ""), String(SETTINGS_SCRIPT.THEME_CATALOG.get_default_id()))
	assert_eq(save_manager.get_value(SAVE_MANAGER_SCRIPT.META_SECTION, SAVE_MANAGER_SCRIPT.VERSION_KEY, 0), SAVE_MANAGER_SCRIPT.SAVE_VERSION)
	assert_eq(save_manager.get_value("record", "best_score", 0), 512)
	assert_eq(save_manager.get_value(SETTINGS_SCRIPT.SECTION, "is_vibration_enabled", true), false)


func test_reload_drops_changes_not_yet_written() -> void:
	var save_manager: Node = _create_save_manager()
	save_manager.set_value("record", "best_score", 7)

	save_manager.load_save()
	await wait_process_frames(1)

	assert_eq(save_manager.get_value("record", "best_score", 0), 0)
	assert_false(FileAccess.file_exists(TEST_SAVE_PATH))


func _create_save_manager() -> Node:
	var save_manager: Node = autofree(SAVE_MANAGER_SCRIPT.new())
	save_manager.save_path = TEST_SAVE_PATH
	save_manager.load_save()
	return save_manager


func _save_value(section: String, key: String, value: Variant) -> Node:
	var save_manager: Node = _create_save_manager()
	save_manager.set_value(section, key, value)
	save_manager.flush()
	return save_manager


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
