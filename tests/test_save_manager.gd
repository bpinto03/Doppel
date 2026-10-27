extends GutTest

const SAVE_MANAGER_SCRIPT: GDScript = preload("res://scripts/autoload/save_manager.gd")
const SETTINGS_SCRIPT: GDScript = preload("res://scripts/autoload/settings.gd")
const TEST_SAVE_PATH: String = "user://test_save.cfg"


func before_each() -> void:
	_delete_test_save()


func after_each() -> void:
	_delete_test_save()


func test_missing_save_starts_empty_with_current_version() -> void:
	var save_manager: Node = _create_save_manager()

	assert_eq(save_manager.get_value("record", "best_score", 0), 0)
	assert_eq(save_manager.get_value(SAVE_MANAGER_SCRIPT.META_SECTION, SAVE_MANAGER_SCRIPT.VERSION_KEY, 0), SAVE_MANAGER_SCRIPT.SAVE_VERSION)


func test_saved_value_survives_a_reload() -> void:
	_create_save_manager().set_value("record", "best_score", 1234)

	var reloaded_manager: Node = _create_save_manager()

	assert_eq(reloaded_manager.get_value("record", "best_score", 0), 1234)


func test_saved_file_records_the_version() -> void:
	_create_save_manager().set_value("record", "best_score", 1)

	var save_file := ConfigFile.new()
	save_file.load(TEST_SAVE_PATH)

	assert_eq(save_file.get_value(SAVE_MANAGER_SCRIPT.META_SECTION, SAVE_MANAGER_SCRIPT.VERSION_KEY, 0), SAVE_MANAGER_SCRIPT.SAVE_VERSION)


func test_write_leaves_no_temporary_file() -> void:
	_create_save_manager().set_value("record", "best_score", 1)

	assert_false(FileAccess.file_exists(TEST_SAVE_PATH + ".tmp"))


func test_unreadable_save_starts_empty() -> void:
	var corrupted_file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	corrupted_file.store_string("[record\nbest_score = ")
	corrupted_file.close()

	var save_manager: Node = _create_save_manager()

	assert_engine_error("ConfigFile parse error")
	assert_eq(save_manager.get_value("record", "best_score", 0), 0)


func test_first_version_save_is_migrated_with_the_default_palette() -> void:
	var first_version_file := ConfigFile.new()
	first_version_file.set_value(SAVE_MANAGER_SCRIPT.META_SECTION, SAVE_MANAGER_SCRIPT.VERSION_KEY, SAVE_MANAGER_SCRIPT.FIRST_SAVE_VERSION)
	first_version_file.set_value("record", "best_score", 512)
	first_version_file.save(TEST_SAVE_PATH)

	var save_manager: Node = _create_save_manager()

	assert_eq(save_manager.get_value(SETTINGS_SCRIPT.SECTION, SETTINGS_SCRIPT.PALETTE_NAME_KEY, ""), SETTINGS_SCRIPT.DEFAULT_PALETTE_NAME)
	assert_eq(save_manager.get_value(SAVE_MANAGER_SCRIPT.META_SECTION, SAVE_MANAGER_SCRIPT.VERSION_KEY, 0), SAVE_MANAGER_SCRIPT.SAVE_VERSION)
	assert_eq(save_manager.get_value("record", "best_score", 0), 512)


func _create_save_manager() -> Node:
	var save_manager: Node = autofree(SAVE_MANAGER_SCRIPT.new())
	save_manager.save_path = TEST_SAVE_PATH
	save_manager.load_save()
	return save_manager


func _delete_test_save() -> void:
	for path: String in [TEST_SAVE_PATH, TEST_SAVE_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
