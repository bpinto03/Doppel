extends GutTest

var _config: BalancingConfig


func before_each() -> void:
	_config = BalancingFixture.create_config()
	_config.coin_minimum_per_game = 5
	_config.coin_score_per_coin = 100
	_config.coin_level_bonus_start_level = 6
	_config.coin_per_level_above_start = 4


func test_empty_game_earns_the_minimum() -> void:
	assert_eq(CoinReward.calculate_coins(0, 0, _config), 5)


func test_minimum_applies_when_the_formula_gives_less() -> void:
	assert_eq(CoinReward.calculate_coins(300, 6, _config), 5)


func test_score_coins_are_rounded_down() -> void:
	_config.coin_minimum_per_game = 0

	assert_eq(CoinReward.calculate_coins(1999, 0, _config), 19)


func test_level_at_bonus_start_earns_no_bonus() -> void:
	_config.coin_minimum_per_game = 0

	assert_eq(CoinReward.calculate_coins(1000, 6, _config), 10)


func test_level_one_above_bonus_start_earns_one_bonus() -> void:
	_config.coin_minimum_per_game = 0

	assert_eq(CoinReward.calculate_coins(1000, 7, _config), 14)


func test_level_below_bonus_start_never_removes_coins() -> void:
	_config.coin_minimum_per_game = 0

	assert_eq(CoinReward.calculate_coins(1000, 2, _config), 10)


func test_shipped_config_examples() -> void:
	var shipped_config: BalancingConfig = load("res://data/balancing.tres")

	assert_eq(CoinReward.calculate_coins(9500, 8, shipped_config), 21)
	assert_eq(CoinReward.calculate_coins(12000, 8, shipped_config), 25)
	assert_eq(CoinReward.calculate_coins(12184, 8, shipped_config), 25)
	assert_eq(CoinReward.calculate_coins(15000, 9, shipped_config), 33)
	assert_eq(CoinReward.calculate_coins(20450, 9, shipped_config), 41)
