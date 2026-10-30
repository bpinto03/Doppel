class_name SimulationStats
extends RefCounted

## Aggregates of a set of simulated games: length, levels, score, chains, merges and column use.

## Highest tile levels whose share of games is reported: 64, 128, 256, 512, 1024, 2048.
const REPORTED_LEVELS: Array[int] = [6, 7, 8, 9, 10, 11]
const FIRST_QUARTILE: float = 0.25
const MEDIAN: float = 0.5
const THIRD_QUARTILE: float = 0.75

var game_count: int
var capped_game_count: int
var placements_mean: float
var placements_median: float
var placements_first_quartile: float
var placements_third_quartile: float
var placements_min: int
var placements_max: int
var score_mean: float
var score_median: float
var max_chain_mean: float
## Games per longest chain length.
var max_chain_distribution: Dictionary[int, int] = {}
## Games per highest level reached.
var highest_level_distribution: Dictionary[int, int] = {}
## Shares of all placements, from 0 to 1.
var merge_placement_share: float
var cross_axis_placement_share: float
## Share of placements per left column, G1 first.
var column_shares: Array[float] = []


static func from_records(records: Array[GameRecord]) -> SimulationStats:
	var stats := SimulationStats.new()
	stats.game_count = records.size()
	var placements: Array[float] = []
	var scores: Array[float] = []
	var max_chains: Array[float] = []
	var total_merge_placements: int = 0
	var total_cross_axis_placements: int = 0
	var column_totals: Array[int] = []
	column_totals.resize(records[0].column_placement_counts.size())
	column_totals.fill(0)
	for record: GameRecord in records:
		placements.append(record.placement_count)
		scores.append(record.score)
		max_chains.append(record.max_chain_length)
		total_merge_placements += record.merge_placement_count
		total_cross_axis_placements += record.cross_axis_placement_count
		_count(stats.max_chain_distribution, record.max_chain_length)
		_count(stats.highest_level_distribution, record.highest_level)
		if record.is_capped:
			stats.capped_game_count += 1
		for column: int in column_totals.size():
			column_totals[column] += record.column_placement_counts[column]
	placements.sort()
	scores.sort()
	var total_placements: int = roundi(_compute_sum(placements))
	stats.placements_mean = _compute_sum(placements) / records.size()
	stats.placements_median = compute_quantile(placements, MEDIAN)
	stats.placements_first_quartile = compute_quantile(placements, FIRST_QUARTILE)
	stats.placements_third_quartile = compute_quantile(placements, THIRD_QUARTILE)
	stats.placements_min = roundi(placements.front())
	stats.placements_max = roundi(placements.back())
	stats.score_mean = _compute_sum(scores) / records.size()
	stats.score_median = compute_quantile(scores, MEDIAN)
	stats.max_chain_mean = _compute_sum(max_chains) / records.size()
	stats.merge_placement_share = _compute_share(total_merge_placements, total_placements)
	stats.cross_axis_placement_share = _compute_share(total_cross_axis_placements, total_placements)
	for column_total: int in column_totals:
		stats.column_shares.append(_compute_share(column_total, total_placements))
	return stats


## Share of games, from 0 to 1, whose highest level is at least this level.
func get_share_reaching(level: int) -> float:
	var reaching_count: int = 0
	for highest_level: int in highest_level_distribution:
		if highest_level >= level:
			reaching_count += highest_level_distribution[highest_level]
	return _compute_share(reaching_count, game_count)


## Linear interpolation between the two closest ranks of the sorted values.
static func compute_quantile(sorted_values: Array[float], quantile: float) -> float:
	var position: float = quantile * (sorted_values.size() - 1)
	var lower_index: int = floori(position)
	var upper_index: int = mini(lower_index + 1, sorted_values.size() - 1)
	return lerpf(sorted_values[lower_index], sorted_values[upper_index], position - lower_index)


static func _count(distribution: Dictionary[int, int], value: int) -> void:
	distribution[value] = distribution.get(value, 0) + 1


static func _compute_sum(values: Array[float]) -> float:
	var total: float = 0.0
	for value: float in values:
		total += value
	return total


static func _compute_share(part: int, whole: int) -> float:
	return float(part) / whole if whole > 0 else 0.0
