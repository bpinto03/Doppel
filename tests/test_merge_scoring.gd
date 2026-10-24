extends GutTest

var _config: BalancingConfig


func before_each() -> void:
	_config = BalancingFixture.create_config()


func test_tile_value_is_two_to_the_power_of_level() -> void:
	assert_eq(MergeScoring.calculate_tile_value(1), 2)
	assert_eq(MergeScoring.calculate_tile_value(12), 4096)


func test_chain_multiplier_grows_by_configured_step() -> void:
	_config.chain_multiplier_step = 0.5

	assert_eq(MergeScoring.calculate_chain_multiplier(1, _config), 1.0)
	assert_eq(MergeScoring.calculate_chain_multiplier(2, _config), 1.5)
	assert_eq(MergeScoring.calculate_chain_multiplier(3, _config), 2.0)


func test_merge_points_are_result_value_times_chain_multiplier() -> void:
	assert_eq(MergeScoring.calculate_merge_points(3, 2, 1, _config), 8)
	assert_eq(MergeScoring.calculate_merge_points(3, 2, 3, _config), 24)


func test_large_group_bonus_is_zero_by_default() -> void:
	assert_eq(MergeScoring.calculate_merge_points(2, 4, 1, _config), 4)


func test_large_group_bonus_applies_per_tile_beyond_a_pair() -> void:
	_config.large_group_bonus_per_extra_tile = 10

	assert_eq(MergeScoring.calculate_merge_points(2, 2, 1, _config), 4)
	assert_eq(MergeScoring.calculate_merge_points(2, 4, 2, _config), (4 + 2 * 10) * 2)
