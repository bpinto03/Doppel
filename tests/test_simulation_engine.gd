extends GutTest

const SEED: int = 1234
const GAME_COUNT: int = 3
const SMALL_CAP: int = 5
const SMALL_ROW_COUNT: int = 4

var _config: BalancingConfig


## A small board keeps the games short.
func before_each() -> void:
	_config = BalancingFixture.create_config()
	_config.row_count = SMALL_ROW_COUNT
	_config.is_distorted_reflection_enabled = true


func test_same_seeds_and_scenario_give_the_same_games() -> void:
	for strategy: PlayStrategy in [RandomStrategy.new(), GreedyStrategy.new(_config), HeuristicStrategy.new(_config)]:
		var first_run: Array[GameRecord] = BalanceSimulator.play_games(_config, strategy, SEED, GAME_COUNT)
		var second_run: Array[GameRecord] = BalanceSimulator.play_games(_config, strategy, SEED, GAME_COUNT)
		assert_eq(_describe(second_run), _describe(first_run), strategy.get_strategy_name())


func test_finished_game_records_its_turns() -> void:
	var record: GameRecord = BalanceSimulator.play_game(_config, GreedyStrategy.new(_config), SEED)

	assert_false(record.is_capped)
	assert_gt(record.placement_count, 0)
	assert_eq(_sum(record.column_placement_counts), record.placement_count)
	assert_between(record.merge_placement_count, 0, record.placement_count)


## A cap below the game length stands for a game that would never end.
func test_placement_cap_ends_a_game_that_goes_on() -> void:
	var record: GameRecord = BalanceSimulator.play_game(_config, GreedyStrategy.new(_config), SEED, SMALL_CAP)

	assert_true(record.is_capped)
	assert_eq(record.placement_count, SMALL_CAP)


func test_scenario_overrides_apply_to_a_copy_only() -> void:
	var base: BalancingConfig = _create_four_tier_config()
	var scenario := SimulationScenario.new("test", {"row_count": 5.0, "is_distorted_reflection_enabled": false, "max_spawn_tier_threshold": 7.0})

	var config: BalancingConfig = scenario.create_config(base)

	assert_eq(config.row_count, 5)
	assert_false(config.is_distorted_reflection_enabled)
	assert_eq(config.spawn_weight_tiers.size(), 2)
	assert_eq(base.row_count, SMALL_ROW_COUNT)
	assert_true(base.is_distorted_reflection_enabled)
	assert_eq(base.spawn_weight_tiers.size(), 4)


func test_unknown_or_mistyped_override_is_reported() -> void:
	assert_eq(SimulationScenario.new("test", {"rows": 5.0}).find_invalid_override(_config), "rows")
	assert_eq(SimulationScenario.new("test", {"row_count": 5.5}).find_invalid_override(_config), "row_count")
	assert_eq(SimulationScenario.new("test", {"row_count": 5.0}).find_invalid_override(_config), "")


func test_shipped_scenarios_are_valid() -> void:
	var scenarios: Array[SimulationScenario] = SimulationScenario.parse_scenarios(FileAccess.get_file_as_string("res://tools/simulation/scenarios.json"))
	var base: BalancingConfig = load("res://data/balancing.tres")

	assert_false(scenarios.is_empty())
	for scenario: SimulationScenario in scenarios:
		assert_eq(scenario.find_invalid_override(base), "", scenario.name)


func test_invalid_scenario_file_gives_no_scenario() -> void:
	assert_true(SimulationScenario.parse_scenarios("{ not json").is_empty())
	assert_true(SimulationScenario.parse_scenarios("{\"scenarios\": [{\"name\": \"no overrides\"}]}").is_empty())


func test_stats_aggregate_known_games() -> void:
	var records: Array[GameRecord] = [
		_create_record(10, 6, 100, 1, [5, 3, 2], 4, 1),
		_create_record(20, 8, 300, 3, [5, 5, 10], 6, 2),
		_create_record(30, 9, 500, 2, [10, 10, 10], 10, 3),
		_create_record(40, 8, 700, 2, [20, 10, 10], 10, 4),
	]

	var stats: SimulationStats = SimulationStats.from_records(records)

	assert_eq(stats.game_count, 4)
	assert_almost_eq(stats.placements_mean, 25.0, 0.001)
	assert_almost_eq(stats.placements_median, 25.0, 0.001)
	assert_almost_eq(stats.placements_first_quartile, 17.5, 0.001)
	assert_almost_eq(stats.placements_third_quartile, 32.5, 0.001)
	assert_eq(stats.placements_min, 10)
	assert_eq(stats.placements_max, 40)
	assert_almost_eq(stats.score_mean, 400.0, 0.001)
	assert_almost_eq(stats.score_median, 400.0, 0.001)
	assert_almost_eq(stats.max_chain_mean, 2.0, 0.001)
	assert_eq(stats.max_chain_distribution, {1: 1, 3: 1, 2: 2})
	assert_almost_eq(stats.get_share_reaching(8), 0.75, 0.001)
	assert_almost_eq(stats.get_share_reaching(9), 0.25, 0.001)
	assert_almost_eq(stats.get_share_reaching(10), 0.0, 0.001)
	assert_almost_eq(stats.merge_placement_share, 0.3, 0.001)
	assert_almost_eq(stats.cross_axis_placement_share, 0.1, 0.001)
	assert_almost_eq(stats.column_shares[0], 0.4, 0.001)
	assert_eq(stats.capped_game_count, 0)


func _create_record(placements: int, highest_level: int, score: int, max_chain: int, columns: Array[int], merges: int, cross_axis: int) -> GameRecord:
	var record := GameRecord.new(columns.size())
	record.placement_count = placements
	record.highest_level = highest_level
	record.score = score
	record.max_chain_length = max_chain
	record.column_placement_counts = columns
	record.merge_placement_count = merges
	record.cross_axis_placement_count = cross_axis
	return record


func _create_four_tier_config() -> BalancingConfig:
	_config.spawn_weight_tiers = [
		BalancingFixture.create_tier(0, {1: 1.0}),
		BalancingFixture.create_tier(7, {2: 1.0}),
		BalancingFixture.create_tier(8, {3: 1.0}),
		BalancingFixture.create_tier(9, {4: 1.0}),
	]
	return _config


func _describe(records: Array[GameRecord]) -> Array[Array]:
	var descriptions: Array[Array] = []
	for record: GameRecord in records:
		descriptions.append([record.placement_count, record.highest_level, record.score, record.max_chain_length, record.column_placement_counts])
	return descriptions


func _sum(values: Array[int]) -> int:
	var total: int = 0
	for value: int in values:
		total += value
	return total
