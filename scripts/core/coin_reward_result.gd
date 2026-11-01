class_name CoinRewardResult
extends RefCounted

## Coins paid at the end of a game, for the game over screen.

var coins_earned: int
var total_after: int


func _init(earned: int, total: int) -> void:
	coins_earned = earned
	total_after = total
