class_name MergeScoring
extends RefCounted

const TILE_VALUE_BASE: int = 2
const PAIR_SIZE: int = 2


static func calculate_tile_value(level: int) -> int:
	return int(pow(TILE_VALUE_BASE, level))


## chain_index starts at 1 for the merges triggered directly by a placement.
static func calculate_chain_multiplier(chain_index: int, config: BalancingConfig) -> float:
	return 1.0 + (chain_index - 1) * config.chain_multiplier_step


static func calculate_merge_points(result_level: int, group_size: int, chain_index: int, config: BalancingConfig) -> int:
	var extra_tile_count: int = maxi(group_size - PAIR_SIZE, 0)
	var base_points: int = calculate_tile_value(result_level) + extra_tile_count * config.large_group_bonus_per_extra_tile
	return roundi(base_points * calculate_chain_multiplier(chain_index, config))
