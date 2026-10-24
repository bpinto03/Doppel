class_name BalancingFixture
extends RefCounted

## Explicit values so tests do not depend on data/balancing.tres tuning.


static func create_config() -> BalancingConfig:
	var config := BalancingConfig.new()
	config.column_count_per_side = 3
	config.row_count = 6
	config.max_tile_level = 12
	config.spawn_weight_tiers = [create_tier(0, {1: 60.0, 2: 30.0, 3: 10.0})]
	config.chain_multiplier_step = 1.0
	config.large_group_bonus_per_extra_tile = 0
	config.is_distorted_reflection_enabled = false
	config.distorted_reflection_period = 5
	config.distorted_reflection_level_bonus = 1
	return config


static func create_tier(min_highest_level: int, level_weights: Dictionary[int, float]) -> SpawnWeightTier:
	var tier := SpawnWeightTier.new()
	tier.min_highest_level = min_highest_level
	tier.level_weights = level_weights
	return tier


static func create_seeded_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng
