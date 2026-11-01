class_name CoinCounter
extends PanelContainer

## Coin icon and the wallet balance, kept up to date by WalletEvents.coins_changed, compact from 10 000 (CoinAmountFormat).
## The amount keeps the width of the widest compact text in its own font, so the counter never resizes with the balance.

const ICON_SIZE := Vector2(64.0, 64.0)
const DIGITS: String = "0123456789"
## One amount per compact shape ("9999", "99,9k", "999k", "9,9M", "999M"); their digits are measured as the widest digit.
## From a billion on, the text is clipped.
const WIDEST_SHAPE_AMOUNTS: Array[int] = [9999, 99999, 999999, 9999999, 999999999]
const DECIMAL_SEPARATOR_KEY: String = "UI_DECIMAL_SEPARATOR"
## The balance is never negative, so this value forces the first display.
const NO_AMOUNT_SHOWN: int = -1

var _shown_coins: int = NO_AMOUNT_SHOWN

@onready var _icon: TextureRect = %Icon
@onready var _value: Label = %Value


func _ready() -> void:
	_icon.custom_minimum_size = ICON_SIZE
	WalletEvents.coins_changed.connect(_show_coins)
	_show_coins(CoinWallet.get_coins())
	_fit_value_width()


## The counter hears of a new theme before its label, whose font is still the old one then: the label is measured afterwards.
func _notification(what: int) -> void:
	if not is_node_ready():
		return
	match what:
		NOTIFICATION_THEME_CHANGED:
			_fit_value_width.call_deferred()
		NOTIFICATION_TRANSLATION_CHANGED:
			_value.text = _format(_shown_coins)
			_fit_value_width.call_deferred()


func get_shown_text() -> String:
	return _value.text


func _show_coins(coins: int) -> void:
	if coins == _shown_coins:
		return
	_shown_coins = coins
	_value.text = _format(coins)


func _format(coins: int) -> String:
	return CoinAmountFormat.format_compact(coins, TranslationServer.translate(DECIMAL_SEPARATOR_KEY))


func _fit_value_width() -> void:
	var font: Font = _value.get_theme_font(&"font")
	var font_size: int = _value.get_theme_font_size(&"font_size")
	var widest_digit: String = _find_widest_digit(font, font_size)
	var widest_text_width: float = 0.0
	for amount: int in WIDEST_SHAPE_AMOUNTS:
		var shape: String = _format(amount)
		for digit: String in DIGITS:
			shape = shape.replace(digit, widest_digit)
		widest_text_width = maxf(widest_text_width, _measure(shape, font, font_size))
	_value.custom_minimum_size.x = ceilf(widest_text_width)


func _find_widest_digit(font: Font, font_size: int) -> String:
	var widest_digit: String = DIGITS[0]
	for digit: String in DIGITS:
		if _measure(digit, font, font_size) > _measure(widest_digit, font, font_size):
			widest_digit = digit
	return widest_digit


static func _measure(text: String, font: Font, font_size: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
