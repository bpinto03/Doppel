class_name CoinWallet
extends RefCounted

## Coins owned by the player, in the wallet save section. The balance never goes below 0.

const SECTION: String = "wallet"
const COINS_KEY: String = "coins"
const EMPTY_BALANCE: int = 0


## A damaged value (negative, or not an integer) reads as an empty wallet.
static func get_coins() -> int:
	var coins: Variant = SaveManager.get_value(SECTION, COINS_KEY, EMPTY_BALANCE)
	if coins is int and coins > EMPTY_BALANCE:
		return coins
	return EMPTY_BALANCE


static func add_coins(amount: int) -> void:
	assert(amount > 0, "Coins to add must be above 0, got %d" % amount)
	_set_coins(get_coins() + amount)


## Leaves the balance untouched and returns false when it is too low.
static func try_spend(amount: int) -> bool:
	assert(amount > 0, "Coins to spend must be above 0, got %d" % amount)
	var coins: int = get_coins()
	if coins < amount:
		return false
	_set_coins(coins - amount)
	return true


static func _set_coins(coins: int) -> void:
	SaveManager.set_value(SECTION, COINS_KEY, coins)
	WalletEvents.coins_changed.emit(coins)
