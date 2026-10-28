extends GutTest

const TEST_SAVE_PATH: String = "user://test_haptics_save.cfg"
const MIN_INTERVAL_MS: int = 80
const DURATION_MS: int = 15
const START_MSEC: int = 1000

var _player_save_path: String
var _haptics: Haptics


func before_each() -> void:
	_player_save_path = SaveManager.save_path
	SaveManager.save_path = TEST_SAVE_PATH
	DirAccess.remove_absolute(TEST_SAVE_PATH)
	SaveManager.load_save()
	var config := HapticsConfig.new()
	config.min_interval_ms = MIN_INTERVAL_MS
	_haptics = Haptics.new(config)


func after_each() -> void:
	DirAccess.remove_absolute(TEST_SAVE_PATH)
	SaveManager.save_path = _player_save_path
	SaveManager.load_save()


func test_first_vibration_goes_through() -> void:
	assert_true(_haptics.try_vibrate(DURATION_MS, START_MSEC))


func test_vibration_closer_than_the_interval_is_dropped() -> void:
	_haptics.try_vibrate(DURATION_MS, START_MSEC)

	assert_false(_haptics.try_vibrate(DURATION_MS, START_MSEC + MIN_INTERVAL_MS - 1))


func test_vibration_after_the_interval_goes_through() -> void:
	_haptics.try_vibrate(DURATION_MS, START_MSEC)

	assert_true(_haptics.try_vibrate(DURATION_MS, START_MSEC + MIN_INTERVAL_MS))


func test_dropped_vibration_does_not_restart_the_interval() -> void:
	_haptics.try_vibrate(DURATION_MS, START_MSEC)
	_haptics.try_vibrate(DURATION_MS, START_MSEC + MIN_INTERVAL_MS / 2)

	assert_true(_haptics.try_vibrate(DURATION_MS, START_MSEC + MIN_INTERVAL_MS))


func test_disabled_vibration_never_vibrates() -> void:
	Settings.is_vibration_enabled = false

	assert_false(_haptics.try_vibrate(DURATION_MS, START_MSEC))


func test_long_chains_vibrate_longer() -> void:
	var config: HapticsConfig = preload("res://data/haptics_config.tres")

	assert_eq(config.get_chain_link_duration_ms(config.big_chain_min_link - 1), config.merge_duration_ms)
	assert_eq(config.get_chain_link_duration_ms(config.big_chain_min_link), config.big_chain_duration_ms)
	assert_gt(config.big_chain_duration_ms, config.merge_duration_ms)
