extends GutTest

const SEED: int = 1234
const GAME_COUNT: int = 2


func test_csv_has_one_line_per_scenario_and_strategy_with_the_effective_config() -> void:
	var config: BalancingConfig = BalancingFixture.create_config()
	config.row_count = 4
	var stats: SimulationStats = SimulationStats.from_records(BalanceSimulator.play_games(config, RandomStrategy.new(), SEED, GAME_COUNT))
	var report := SimulationReport.new()
	report.add_row("small", "random", config, stats)
	report.add_row("small", "random_again", config, stats)

	var lines: PackedStringArray = report.build_csv_text().strip_edges().split("\n")

	assert_eq(lines.size(), 3)
	var header: PackedStringArray = lines[0].split(SimulationReport.CSV_SEPARATOR)
	var values: PackedStringArray = lines[1].split(SimulationReport.CSV_SEPARATOR)
	assert_eq(values.size(), header.size())
	assert_eq(values[header.find("row_count")], "4")
	assert_eq(values[header.find("spawn_tier_thresholds")], "0")
	assert_eq(values[header.find("games")], str(GAME_COUNT))


func test_estimated_minutes_follow_the_seconds_per_placement() -> void:
	var stats := SimulationStats.new()
	stats.placements_mean = 90.0

	assert_almost_eq(SimulationReport.estimate_minutes(stats), 90.0 * SimulationReport.SECONDS_PER_PLACEMENT / 60.0, 0.001)
