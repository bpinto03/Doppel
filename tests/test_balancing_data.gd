extends GutTest

## Checks data/balancing.tres as shipped, so a broken or temporarily edited value fails ./run_tests.sh.

## Update when the thresholds change on purpose (see docs/balancing.md).
const SHIPPED_TIER_THRESHOLDS: Array[int] = [0, 7, 8, 9]

var _config: BalancingConfig = load("res://data/balancing.tres")


func test_board_has_a_size() -> void:
	assert_gt(_config.row_count, 0)
	assert_gt(_config.column_count_per_side, 0)


func test_a_tier_applies_from_the_start() -> void:
	assert_false(_config.find_spawn_weights(0).is_empty())


func test_tier_thresholds_are_the_shipped_ones() -> void:
	assert_eq(_get_sorted_thresholds(), SHIPPED_TIER_THRESHOLDS)


## Two tiers on the same threshold would hide one of them.
func test_tier_thresholds_are_all_different() -> void:
	var thresholds: Array[int] = _get_sorted_thresholds()

	for index: int in range(1, thresholds.size()):
		assert_ne(thresholds[index], thresholds[index - 1])


func test_every_tier_draws_levels_in_bounds_with_positive_weights() -> void:
	for tier: SpawnWeightTier in _config.spawn_weight_tiers:
		assert_false(tier.level_weights.is_empty(), "Tier %d has no level" % tier.min_highest_level)
		for level: int in tier.level_weights:
			assert_between(level, 1, _config.max_tile_level, "Tier %d" % tier.min_highest_level)
			assert_gt(tier.level_weights[level], 0.0, "Tier %d, level %d" % [tier.min_highest_level, level])


func _get_sorted_thresholds() -> Array[int]:
	var thresholds: Array[int] = []
	for tier: SpawnWeightTier in _config.spawn_weight_tiers:
		thresholds.append(tier.min_highest_level)
	thresholds.sort()
	return thresholds
