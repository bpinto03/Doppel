extends GutTest

const TEST_SAVE_PATH: String = "user://test_audio_manager_save.cfg"
const AUDIO_MANAGER_SCRIPT: GDScript = preload("res://scripts/autoload/audio_manager.gd")
const HALF_VOLUME: float = 0.5
const DECIBEL_TOLERANCE: float = 0.01

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
	AudioManager.apply_settings()


func test_saved_disabled_sound_mutes_the_effect_bus_at_startup() -> void:
	# Written to the save directly, so no settings change notifies the running manager.
	SaveManager.set_value(Settings.SECTION, "is_sound_enabled", false)
	SaveManager.set_value(Settings.SECTION, "is_music_enabled", false)

	add_child_autofree(AUDIO_MANAGER_SCRIPT.new())

	assert_true(_is_bus_muted(AudioManager.SFX_BUS))
	assert_true(_is_bus_muted(AudioManager.MUSIC_BUS))
	assert_false(_is_bus_muted(AudioManager.MASTER_BUS))


func test_enabled_sound_leaves_the_effect_bus_audible() -> void:
	AudioManager.apply_settings()

	assert_false(_is_bus_muted(AudioManager.SFX_BUS))


func test_bus_volume_is_applied_in_decibels() -> void:
	Settings.set_bus_volume(AudioManager.SFX_BUS, HALF_VOLUME)

	assert_almost_eq(_get_bus_volume_db(AudioManager.SFX_BUS), linear_to_db(HALF_VOLUME), DECIBEL_TOLERANCE)
	assert_false(_is_bus_muted(AudioManager.SFX_BUS))


func test_zero_volume_mutes_the_bus() -> void:
	Settings.set_bus_volume(AudioManager.MUSIC_BUS, 0.0)

	assert_true(_is_bus_muted(AudioManager.MUSIC_BUS))


func _is_bus_muted(bus_name: StringName) -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(bus_name))


func _get_bus_volume_db(bus_name: StringName) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name))
