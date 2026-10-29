extends GutTest

const TEST_SAVE_PATH: String = "user://test_haptics_save.cfg"
const HAPTICS_MANAGER_SCRIPT: GDScript = preload("res://scripts/autoload/haptics_manager.gd")
const CONFIG: HapticsConfig = preload("res://data/haptics_config.tres")
const START_MSEC: int = 1000
const AMPLITUDE_TOLERANCE: float = 0.0001

var _player_save_path: String
## Never added to the tree, so it never processes and never makes the device vibrate.
var _manager: Node


func before_each() -> void:
	_player_save_path = SaveManager.save_path
	SaveManager.save_path = TEST_SAVE_PATH
	DirAccess.remove_absolute(TEST_SAVE_PATH)
	SaveManager.load_save()
	_manager = autofree(HAPTICS_MANAGER_SCRIPT.new())


func after_each() -> void:
	DirAccess.remove_absolute(TEST_SAVE_PATH)
	SaveManager.save_path = _player_save_path
	SaveManager.load_save()


func test_requested_pulse_is_sent() -> void:
	var pulse := _create_pulse(20, 0.5)
	_manager.request(pulse)

	assert_eq(_manager.take_pending_pulse(START_MSEC), pulse)


func test_nothing_is_sent_without_a_request() -> void:
	assert_null(_manager.take_pending_pulse(START_MSEC))


func test_pulses_of_the_same_frame_send_only_the_strongest() -> void:
	var strong := _create_pulse(40, 0.5)
	_manager.request(_create_pulse(20, 0.5))
	_manager.request(strong)
	_manager.request(_create_pulse(30, 0.9))

	assert_eq(_manager.take_pending_pulse(START_MSEC), strong)
	assert_null(_manager.take_pending_pulse(START_MSEC))


func test_equal_durations_are_compared_by_amplitude() -> void:
	assert_true(_create_pulse(20, 0.6).is_stronger_than(_create_pulse(20, 0.5)))
	assert_false(_create_pulse(20, 0.5).is_stronger_than(_create_pulse(20, 0.5)))


func test_weaker_or_equal_pulse_closer_than_the_interval_is_dropped() -> void:
	_send(_create_pulse(30, 0.5), START_MSEC)

	assert_null(_send(_create_pulse(30, 0.5), START_MSEC + CONFIG.min_interval_ms - 1))
	assert_null(_send(_create_pulse(20, 0.5), START_MSEC + CONFIG.min_interval_ms - 1))


func test_stronger_pulse_closer_than_the_interval_goes_through() -> void:
	_send(_create_pulse(30, 0.5), START_MSEC)
	var stronger := _create_pulse(40, 0.6)

	assert_eq(_send(stronger, START_MSEC + 1), stronger)


func test_pulse_after_the_interval_goes_through() -> void:
	_send(_create_pulse(30, 0.5), START_MSEC)
	var weaker := _create_pulse(20, 0.3)

	assert_eq(_send(weaker, START_MSEC + CONFIG.min_interval_ms), weaker)


func test_dropped_pulse_does_not_restart_the_interval() -> void:
	_send(_create_pulse(30, 0.5), START_MSEC)
	_send(_create_pulse(30, 0.5), START_MSEC + CONFIG.min_interval_ms / 2)

	assert_not_null(_send(_create_pulse(30, 0.5), START_MSEC + CONFIG.min_interval_ms))


func test_disabled_vibration_never_sends() -> void:
	Settings.is_vibration_enabled = false
	_manager.request(_create_pulse(30, 0.5))

	assert_null(_manager.take_pending_pulse(START_MSEC))


func test_sent_pulse_is_reported() -> void:
	watch_signals(_manager)
	var pulse := _create_pulse(30, 0.5)

	_send(pulse, START_MSEC)

	assert_signal_emitted_with_parameters(_manager, "pulse_sent", [pulse])


func test_first_chain_link_vibrates_as_a_merge() -> void:
	_assert_same_pulse(CONFIG.get_chain_link_pulse(1), CONFIG.merge)


func test_each_chain_link_vibrates_stronger_until_the_big_combo() -> void:
	for chain_link: int in range(2, CONFIG.big_combo_min_link + 1):
		var pulse: HapticPulse = CONFIG.get_chain_link_pulse(chain_link)
		assert_true(pulse.is_stronger_than(CONFIG.get_chain_link_pulse(chain_link - 1)), "link %d" % chain_link)
		assert_gt(pulse.amplitude, CONFIG.get_chain_link_pulse(chain_link - 1).amplitude, "link %d" % chain_link)


func test_chain_links_from_the_big_combo_on_stay_at_the_cap() -> void:
	_assert_same_pulse(CONFIG.get_chain_link_pulse(CONFIG.big_combo_min_link), CONFIG.big_combo)
	_assert_same_pulse(CONFIG.get_chain_link_pulse(CONFIG.big_combo_min_link + 10), CONFIG.big_combo)


func test_disabled_vibration_drops_even_a_big_combo() -> void:
	Settings.is_vibration_enabled = false
	_manager.request(CONFIG.get_chain_link_pulse(CONFIG.big_combo_min_link))

	assert_null(_manager.take_pending_pulse(START_MSEC))


func test_game_over_is_stronger_than_any_chain_link() -> void:
	assert_true(CONFIG.game_over.is_stronger_than(CONFIG.big_combo))


func _assert_same_pulse(actual: HapticPulse, expected: HapticPulse) -> void:
	assert_eq(actual.duration_ms, expected.duration_ms)
	assert_almost_eq(actual.amplitude, expected.amplitude, AMPLITUDE_TOLERANCE)


func _send(pulse: HapticPulse, now_msec: int) -> HapticPulse:
	_manager.request(pulse)
	return _manager.take_pending_pulse(now_msec)


func _create_pulse(duration_ms: int, amplitude: float) -> HapticPulse:
	var pulse := HapticPulse.new()
	pulse.duration_ms = duration_ms
	pulse.amplitude = amplitude
	return pulse
