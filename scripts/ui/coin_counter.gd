class_name CoinCounter
extends PanelContainer

## Coin icon and the wallet balance, kept up to date by WalletEvents.coins_changed.
## The amount keeps the width of MAX_SHOWN_DIGITS digits, so the counter never resizes; a longer amount is clipped.

const ICON_SIZE := Vector2(64.0, 64.0)
const MAX_SHOWN_DIGITS: int = 6
const DIGITS: String = "0123456789"
## The balance is never negative, so this value forces the first display.
const NO_AMOUNT_SHOWN: int = -1

var _shown_coins: int = NO_AMOUNT_SHOWN

@onready var _icon: TextureRect = %Icon
@onready var _value: Label = %Value


func _ready() -> void:
	_icon.custom_minimum_size = ICON_SIZE
	_fit_value_width()
	WalletEvents.coins_changed.connect(_show_coins)
	_show_coins(CoinWallet.get_coins())


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_fit_value_width()


func get_shown_text() -> String:
	return _value.text


## Room for MAX_SHOWN_DIGITS of the widest digit of the current font.
func get_value_width() -> float:
	return _value.custom_minimum_size.x


func _show_coins(coins: int) -> void:
	if coins == _shown_coins:
		return
	_shown_coins = coins
	_value.text = str(coins)


func _fit_value_width() -> void:
	var font: Font = _value.get_theme_font(&"font")
	var font_size: int = _value.get_theme_font_size(&"font_size")
	var widest_digit: float = 0.0
	for digit: String in DIGITS:
		widest_digit = maxf(widest_digit, font.get_string_size(digit, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	_value.custom_minimum_size.x = ceilf(widest_digit * MAX_SHOWN_DIGITS)
