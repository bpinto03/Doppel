extends GutTest

const DRAW_COUNT: int = 200


func test_same_seed_produces_same_sequence() -> void:
	var config: BalancingConfig = BalancingFixture.create_config()

	assert_eq(_draw_sequence(config, 42), _draw_sequence(config, 42))


func test_different_seeds_produce_different_sequences() -> void:
	var config: BalancingConfig = BalancingFixture.create_config()

	assert_ne(_draw_sequence(config, 42), _draw_sequence(config, 7))


func test_draws_only_levels_with_weight() -> void:
	var config: BalancingConfig = BalancingFixture.create_config()

	for level: int in _draw_sequence(config, 1):
		assert_between(level, 1, 3)


func test_advance_promotes_next_tile_to_current() -> void:
	var generator := TileGenerator.new(BalancingFixture.create_config(), BalancingFixture.create_seeded_rng(3), 0)
	var previewed_level: int = generator.next_level

	generator.advance(0)

	assert_eq(generator.current_level, previewed_level)


func test_highest_unlocked_tier_is_used() -> void:
	var config: BalancingConfig = BalancingFixture.create_config()
	config.spawn_weight_tiers.append(BalancingFixture.create_tier(7, {5: 1.0}))
	var generator := TileGenerator.new(config, BalancingFixture.create_seeded_rng(3), 0)

	assert_eq(generator.draw_level(7), 5)
	assert_ne(generator.draw_level(6), 5)


func test_shipped_balancing_data_loads_with_a_starting_tier() -> void:
	var config: BalancingConfig = load("res://data/balancing.tres")

	assert_false(config.find_spawn_weights(0).is_empty())
	assert_gt(config.row_count, 0)
	assert_gt(config.column_count_per_side, 0)


func _draw_sequence(config: BalancingConfig, seed_value: int) -> Array[int]:
	var generator := TileGenerator.new(config, BalancingFixture.create_seeded_rng(seed_value), 0)
	var levels: Array[int] = []
	for i: int in DRAW_COUNT:
		levels.append(generator.current_level)
		generator.advance(0)
	return levels
