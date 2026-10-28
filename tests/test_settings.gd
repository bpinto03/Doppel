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


func test_sound_music_and_vibration_are_enabled_by_default() -> void:
	assert_true(Settings.is_sound_enabled)
	assert_true(Settings.is_music_enabled)
	assert_true(Settings.is_vibration_enabled)


func test_disabled_vibration_survives_a_reload() -> void:
	Settings.is_vibration_enabled = false

	SaveManager.load_save()

	assert_false(Settings.is_vibration_enabled)


func test_bus_volumes_are_full_by_default() -> void:
	for bus_name: StringName in [AudioManager.MASTER_BUS, AudioManager.SFX_BUS, AudioManager.MUSIC_BUS]:
		assert_eq(Settings.get_bus_volume(bus_name), Settings.DEFAULT_BUS_VOLUME)


func test_bus_volume_survives_a_reload() -> void:
	Settings.set_bus_volume(AudioManager.SFX_BUS, 0.25)

	SaveManager.load_save()

	assert_eq(Settings.get_bus_volume(AudioManager.SFX_BUS), 0.25)
	assert_eq(Settings.get_bus_volume(AudioManager.MUSIC_BUS), Settings.DEFAULT_BUS_VOLUME)
