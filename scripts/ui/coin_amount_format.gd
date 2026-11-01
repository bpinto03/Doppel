class_name CoinAmountFormat
extends RefCounted

## Short form of a coin balance: exact below 10 000, then thousands ("12,5k", "100k") and millions ("1,2M", "12M").
## Always rounded down, so the amount shown never exceeds the balance. The suffixes are the same in every language.

const EXACT_LIMIT: int = 10000
const THOUSAND: int = 1000
const MILLION: int = 1000000
## Below this many units, the amount keeps one decimal.
const THOUSANDS_DECIMAL_LIMIT: int = 100
const MILLIONS_DECIMAL_LIMIT: int = 10
const THOUSANDS_SUFFIX: String = "k"
const MILLIONS_SUFFIX: String = "M"
const TENTHS_PER_UNIT: int = 10


static func format_compact(amount: int, decimal_separator: String) -> String:
	var shown_amount: int = maxi(amount, 0)
	if shown_amount < EXACT_LIMIT:
		return str(shown_amount)
	if shown_amount < MILLION:
		return _format_in_unit(shown_amount, THOUSAND, THOUSANDS_DECIMAL_LIMIT, THOUSANDS_SUFFIX, decimal_separator)
	return _format_in_unit(shown_amount, MILLION, MILLIONS_DECIMAL_LIMIT, MILLIONS_SUFFIX, decimal_separator)


## A zero decimal is left out: "12k", not "12,0k".
static func _format_in_unit(amount: int, unit: int, decimal_limit: int, suffix: String, decimal_separator: String) -> String:
	var whole_units: int = floori(float(amount) / unit)
	if whole_units >= decimal_limit:
		return "%d%s" % [whole_units, suffix]
	var tenths: int = floori(float(amount) * TENTHS_PER_UNIT / unit) % TENTHS_PER_UNIT
	if tenths == 0:
		return "%d%s" % [whole_units, suffix]
	return "%d%s%d%s" % [whole_units, decimal_separator, tenths, suffix]
