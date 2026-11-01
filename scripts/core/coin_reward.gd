class_name CoinReward
extends RefCounted


static func calculate_coins(score: int, highest_level: int, config: BalancingConfig) -> int:
	assert(config.coin_score_per_coin > 0, "coin_score_per_coin must be above 0")
	var score_coins: int = floori(float(score) / config.coin_score_per_coin)
	var levels_above_start: int = maxi(0, highest_level - config.coin_level_bonus_start_level)
	var level_coins: int = levels_above_start * config.coin_per_level_above_start
	return maxi(config.coin_minimum_per_game, score_coins + level_coins)
