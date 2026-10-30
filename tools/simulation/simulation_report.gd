class_name SimulationReport
extends RefCounted

## Turns simulation results into a console table and CSV text, one row per scenario and strategy. Writing files is the runner's job.

## TO CALIBRATE from real games: seconds a player spends per placement. Only used for the estimated game duration.
const SECONDS_PER_PLACEMENT: float = 2.0
const SECONDS_PER_MINUTE: float = 60.0
const PERCENT: float = 100.0
const CSV_SEPARATOR: String = ","
const LIST_SEPARATOR: String = " "
const COLUMN_NAME_PREFIX: String = "G"
const STRATEGY_COLUMN_WIDTH: int = 10
const NUMBER_COLUMN_WIDTH: int = 8


class Row:
	var scenario_name: String
	var strategy_name: String
	var config: BalancingConfig
	var stats: SimulationStats

	func _init(row_scenario_name: String, row_strategy_name: String, row_config: BalancingConfig, row_stats: SimulationStats) -> void:
		scenario_name = row_scenario_name
		strategy_name = row_strategy_name
		config = row_config
		stats = row_stats


var _rows: Array[Row] = []


func add_row(scenario_name: String, strategy_name: String, config: BalancingConfig, stats: SimulationStats) -> void:
	_rows.append(Row.new(scenario_name, strategy_name, config, stats))


## Board, distorted reflection and spawn tiers that the scenario actually played.
static func describe_config(config: BalancingConfig) -> String:
	var distortion: String = "every %d" % config.distorted_reflection_period if config.is_distorted_reflection_enabled else "off"
	return "board %dx%d (%d columns per side), distorted reflection %s, spawn tier thresholds %s (highest tiles %s)" % [
		config.column_count_per_side * BoardState.SIDE_COUNT,
		config.row_count,
		config.column_count_per_side,
		distortion,
		LIST_SEPARATOR.join(_get_tier_thresholds(config)),
		LIST_SEPARATOR.join(_get_tier_threshold_values(config)),
	]


func build_console_text() -> String:
	var lines: PackedStringArray = []
	var current_scenario_name: String = ""
	for row: Row in _rows:
		if row.scenario_name != current_scenario_name:
			current_scenario_name = row.scenario_name
			lines.append("")
			lines.append("== %s: %s, %d games" % [row.scenario_name, describe_config(row.config), row.stats.game_count])
			lines.append(_build_console_header(row.config.column_count_per_side))
		lines.append(_build_console_line(row))
	return "\n".join(lines)


func build_csv_text() -> String:
	var column_count: int = _get_most_columns_per_side()
	var lines: PackedStringArray = [CSV_SEPARATOR.join(_build_csv_header(column_count))]
	for row: Row in _rows:
		lines.append(CSV_SEPARATOR.join(_build_csv_values(row, column_count)))
	return "\n".join(lines) + "\n"


static func estimate_minutes(stats: SimulationStats) -> float:
	return stats.placements_mean * SECONDS_PER_PLACEMENT / SECONDS_PER_MINUTE


func _build_console_header(column_count_per_side: int) -> String:
	var cells: PackedStringArray = [
		"strategy".rpad(STRATEGY_COLUMN_WIDTH), "mean", "median", "q1", "q3", "min", "max",
	]
	for level: int in SimulationStats.REPORTED_LEVELS:
		cells.append(">=%d" % MergeScoring.calculate_tile_value(level))
	cells.append_array(["score", "chain", "merge%", "axis%"])
	for column: int in column_count_per_side:
		cells.append("%s%d%%" % [COLUMN_NAME_PREFIX, column + 1])
	cells.append_array(["capped", "minutes"])
	return _pad_cells(cells)


func _build_console_line(row: Row) -> String:
	var stats: SimulationStats = row.stats
	var cells: PackedStringArray = [
		row.strategy_name.rpad(STRATEGY_COLUMN_WIDTH),
		"%.1f" % stats.placements_mean,
		"%.1f" % stats.placements_median,
		"%.1f" % stats.placements_first_quartile,
		"%.1f" % stats.placements_third_quartile,
		str(stats.placements_min),
		str(stats.placements_max),
	]
	for level: int in SimulationStats.REPORTED_LEVELS:
		cells.append("%.1f%%" % (stats.get_share_reaching(level) * PERCENT))
	cells.append_array([
		"%.0f" % stats.score_mean,
		"%.2f" % stats.max_chain_mean,
		"%.1f" % (stats.merge_placement_share * PERCENT),
		"%.1f" % (stats.cross_axis_placement_share * PERCENT),
	])
	for share: float in stats.column_shares:
		cells.append("%.1f" % (share * PERCENT))
	cells.append_array([str(stats.capped_game_count), "%.1f" % estimate_minutes(stats)])
	return _pad_cells(cells)


func _build_csv_header(column_count: int) -> PackedStringArray:
	var header: PackedStringArray = [
		"scenario", "strategy", "columns_per_side", "row_count", "is_distorted_reflection_enabled", "distorted_reflection_period",
		"spawn_tier_thresholds", "games", "capped_games", "placements_mean", "placements_median", "placements_q1",
		"placements_q3", "placements_min", "placements_max",
	]
	for level: int in SimulationStats.REPORTED_LEVELS:
		header.append("share_reaching_%d" % MergeScoring.calculate_tile_value(level))
	header.append_array([
		"score_mean", "score_median", "max_chain_mean", "max_chain_distribution", "highest_level_distribution",
		"merge_placement_share", "cross_axis_placement_share",
	])
	for column: int in column_count:
		header.append("column_share_%s%d" % [COLUMN_NAME_PREFIX, column + 1])
	header.append("estimated_minutes")
	return header


func _build_csv_values(row: Row, column_count: int) -> PackedStringArray:
	var stats: SimulationStats = row.stats
	var values: PackedStringArray = [
		row.scenario_name, row.strategy_name, str(row.config.column_count_per_side), str(row.config.row_count),
		str(row.config.is_distorted_reflection_enabled), str(row.config.distorted_reflection_period),
		LIST_SEPARATOR.join(_get_tier_thresholds(row.config)), str(stats.game_count), str(stats.capped_game_count),
		str(stats.placements_mean), str(stats.placements_median), str(stats.placements_first_quartile),
		str(stats.placements_third_quartile), str(stats.placements_min), str(stats.placements_max),
	]
	for level: int in SimulationStats.REPORTED_LEVELS:
		values.append(str(stats.get_share_reaching(level)))
	values.append_array([
		str(stats.score_mean), str(stats.score_median), str(stats.max_chain_mean),
		_describe_distribution(stats.max_chain_distribution), _describe_distribution(stats.highest_level_distribution),
		str(stats.merge_placement_share), str(stats.cross_axis_placement_share),
	])
	for column: int in column_count:
		values.append(str(stats.column_shares[column]) if column < stats.column_shares.size() else "")
	values.append(str(estimate_minutes(stats)))
	return values


func _get_most_columns_per_side() -> int:
	var most_columns: int = 0
	for row: Row in _rows:
		most_columns = maxi(most_columns, row.config.column_count_per_side)
	return most_columns


## "value:count" pairs, sorted by value.
static func _describe_distribution(distribution: Dictionary[int, int]) -> String:
	var values: Array[int] = distribution.keys()
	values.sort()
	var pairs: PackedStringArray = []
	for value: int in values:
		pairs.append("%d:%d" % [value, distribution[value]])
	return LIST_SEPARATOR.join(pairs)


static func _get_tier_thresholds(config: BalancingConfig) -> PackedStringArray:
	var thresholds: Array[int] = []
	for tier: SpawnWeightTier in config.spawn_weight_tiers:
		thresholds.append(tier.min_highest_level)
	thresholds.sort()
	var texts: PackedStringArray = []
	for threshold: int in thresholds:
		texts.append(str(threshold))
	return texts


static func _get_tier_threshold_values(config: BalancingConfig) -> PackedStringArray:
	var texts: PackedStringArray = []
	for threshold: String in _get_tier_thresholds(config):
		texts.append(str(MergeScoring.calculate_tile_value(int(threshold))) if int(threshold) > 0 else "start")
	return texts


static func _pad_cells(cells: PackedStringArray) -> String:
	var padded: PackedStringArray = []
	for cell: String in cells:
		padded.append(cell.lpad(NUMBER_COLUMN_WIDTH))
	return " ".join(padded)
