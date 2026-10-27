extends GutTest

const TEST_SAVE_PATH: String = "user://test_settings_save.cfg"

var _player_save_path: String


func before_each() -> void:
	_player_save_path = SaveManager.save_path
	SaveManager.save_path = TEST_SAVE_PATH
	DirAccess.remove_absolute(TEST_SAVE_PATH)
	SaveManager.load_save()


func after_each() -> void:
	DirAccess.remove_absolute(TEST_SAVE_PATH)
	SaveManager.save_path = _player_save_path
	SaveManager.load_save()


func test_screen_shake_is_enabled_by_default() -> void:
	assert_true(Settings.is_screen_shake_enabled)


func test_disabled_screen_shake_survives_a_reload() -> void:
	Settings.is_screen_shake_enabled = false

	SaveManager.load_save()

	assert_false(Settings.is_screen_shake_enabled)
