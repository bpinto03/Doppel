extends GutTest

const CONFIG: GameOverEffectsConfig = preload("res://data/game_over_effects.tres")
const COLORS: Array[Color] = [Color.RED, Color.GREEN, Color.BLUE]

var _burst: ConfettiBurst


func before_each() -> void:
	_burst = ConfettiBurst.new(CONFIG)
	add_child_autofree(_burst)


func test_every_value_is_positive() -> void:
	for property: String in ["confetti_amount", "record_confetti_amount", "max_confetti_amount", "confetti_lifetime", "confetti_min_speed", "confetti_max_speed", "confetti_gravity", "confetti_min_size", "confetti_max_size", "confetti_max_spin", "appear_duration", "appear_start_scale", "halo_turn_duration", "halo_breath_duration", "halo_min_opacity"]:
		assert_gt(float(CONFIG.get(property)), 0.0, property)


func test_record_burst_is_larger_and_both_stay_under_the_cap() -> void:
	assert_gt(CONFIG.record_confetti_amount, CONFIG.confetti_amount)
	assert_lte(CONFIG.record_confetti_amount, CONFIG.max_confetti_amount)


func test_ranges_go_from_min_to_max() -> void:
	assert_lte(CONFIG.confetti_min_speed, CONFIG.confetti_max_speed)
	assert_lte(CONFIG.confetti_min_size, CONFIG.confetti_max_size)
	assert_lt(CONFIG.appear_start_scale, 1.0)
	assert_lt(CONFIG.halo_min_opacity, 1.0)


func test_burst_uses_the_record_amount_only_for_a_record() -> void:
	_burst.burst(COLORS, false)
	assert_eq(_burst.get_amount(), CONFIG.confetti_amount)

	_burst.burst(COLORS, true)
	assert_eq(_burst.get_amount(), CONFIG.record_confetti_amount)


func test_clear_removes_the_confetti_at_once() -> void:
	_burst.burst(COLORS, false)
	await wait_process_frames(2)
	assert_true(_burst.is_showing_confetti())

	_burst.clear()

	assert_false(_burst.is_showing_confetti())
