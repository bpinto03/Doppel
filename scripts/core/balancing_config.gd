class_name BalancingConfig
extends Resource

@export_group("Saves")
## Saved games made under another rules version are discarded. See docs/balancing.md.
@export var rules_version: int

@export_group("Board")
@export var column_count_per_side: int
@export var row_count: int
@export var max_tile_level: int

@export_group("Merging")
## Defaults to true so the .tres stores it explicitly when turned off.
@export var is_cross_axis_merge_enabled: bool = true

@export_group("Spawning")
@export var spawn_weight_tiers: Array[SpawnWeightTier]

@export_group("Scoring")
@export var chain_multiplier_step: float
@export var large_group_bonus_per_extra_tile: int

@export_group("Distorted reflection")
@export var is_distorted_reflection_enabled: bool
@export var distorted_reflection_period: int
@export var distorted_reflection_level_bonus: int

@export_group("Coins")
@export var coin_minimum_per_game: int
## Must stay above 0: the score is divided by it.
@export var coin_score_per_coin: int
@export var coin_level_bonus_start_level: int
@export var coin_per_level_above_start: int


func find_spawn_weights(highest_level_reached: int) -> Dictionary[int, float]:
	var selected_tier: SpawnWeightTier = null
	for tier: SpawnWeightTier in spawn_weight_tiers:
		var is_tier_unlocked: bool = tier.min_highest_level <= highest_level_reached
		if is_tier_unlocked and (selected_tier == null or tier.min_highest_level > selected_tier.min_highest_level):
			selected_tier = tier
	assert(selected_tier != null, "No spawn weight tier applies to level %d" % highest_level_reached)
	return selected_tier.level_weights
