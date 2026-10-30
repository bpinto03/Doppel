extends GutTest

const DRAW_COUNT: int = 200
const TURN_COUNT: int = 20
const ADVANCED_THRESHOLD: int = 7
const EXPERT_THRESHOLD: int = 8
const MASTER_THRESHOLD: int = 9
const MASTER_ONLY_LEVEL: int = 7


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


func test_scripted_levels_are_drawn_in_order_before_weighted_draws() -> void:
	var config: BalancingConfig = BalancingFixture.create_config()
	config.spawn_weight_tiers = [BalancingFixture.create_tier(0, {1: 1.0})]
	var generator := TileGenerator.new(config, BalancingFixture.create_seeded_rng(3), 0, [4, 6, 5])

	assert_eq(generator.current_level, 4)
	assert_eq(generator.next_level, 6)
	generator.advance(0)
	assert_eq(generator.next_level, 5)
	generator.advance(0)
	assert_eq(generator.next_level, 1)


## Each threshold is checked one level below and at the threshold, with the tiers listed out of order.
func test_tier_follows_the_highest_threshold_reached_among_four() -> void:
	var config: BalancingConfig = _create_four_tier_config()
	var expected_tiers: Dictionary[int, int] = {0: 0, 6: 0, 7: ADVANCED_THRESHOLD, 8: EXPERT_THRESHOLD, 9: MASTER_THRESHOLD, 12: MASTER_THRESHOLD}

	for highest_level: int in expected_tiers:
		var expected_weights: Dictionary[int, float] = _find_tier(config, expected_tiers[highest_level]).level_weights
		assert_eq(config.find_spawn_weights(highest_level), expected_weights, "Highest level %d" % highest_level)


## The master tier draws a level no other tier has, so any draw from a lower tier shows.
func test_reached_tier_stays_for_the_rest_of_the_game() -> void:
	var config: BalancingConfig = _create_four_tier_config()
	_find_tier(config, MASTER_THRESHOLD).level_weights = {MASTER_ONLY_LEVEL: 1.0}
	var session := GameSession.new(config, BalancingFixture.create_seeded_rng(5))
	session.highest_level_reached = MASTER_THRESHOLD

	for turn: int in TURN_COUNT:
		session.play_column(_find_first_playable_column(session))
		if session.is_game_over:
			break
		assert_eq(session.tile_generator.next_level, MASTER_ONLY_LEVEL, "Turn %d" % turn)


func test_each_tier_draws_only_its_levels_and_repeats_with_the_same_seed() -> void:
	var config: BalancingConfig = _create_four_tier_config()

	for tier: SpawnWeightTier in config.spawn_weight_tiers:
		var sequence: Array[int] = _draw_sequence(config, 42, tier.min_highest_level)
		assert_eq(_draw_sequence(config, 42, tier.min_highest_level), sequence, "Tier %d" % tier.min_highest_level)
		for level: int in sequence:
			assert_has(tier.level_weights.keys(), level, "Tier %d" % tier.min_highest_level)


func _draw_sequence(config: BalancingConfig, seed_value: int, highest_level: int = 0) -> Array[int]:
	var generator := TileGenerator.new(config, BalancingFixture.create_seeded_rng(seed_value), highest_level)
	var levels: Array[int] = []
	for i: int in DRAW_COUNT:
		levels.append(generator.current_level)
		generator.advance(highest_level)
	return levels


func _create_four_tier_config() -> BalancingConfig:
	var config: BalancingConfig = BalancingFixture.create_config()
	config.spawn_weight_tiers = [
		BalancingFixture.create_tier(MASTER_THRESHOLD, {1: 30.0, 2: 30.0, 3: 20.0, 4: 13.0, 5: 6.0, 6: 1.0}),
		BalancingFixture.create_tier(0, {1: 60.0, 2: 30.0, 3: 10.0}),
		BalancingFixture.create_tier(EXPERT_THRESHOLD, {1: 40.0, 2: 30.0, 3: 20.0, 4: 8.0, 5: 2.0}),
		BalancingFixture.create_tier(ADVANCED_THRESHOLD, {1: 50.0, 2: 30.0, 3: 15.0, 4: 5.0}),
	]
	return config


func _find_tier(config: BalancingConfig, threshold: int) -> SpawnWeightTier:
	for tier: SpawnWeightTier in config.spawn_weight_tiers:
		if tier.min_highest_level == threshold:
			return tier
	return null


func _find_first_playable_column(session: GameSession) -> int:
	for column: int in session.board.column_count_per_side:
		if session.can_play_column(column):
			return column
	return -1
