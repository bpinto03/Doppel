extends GutTest

const FRENCH_SEPARATOR: String = ","
const ENGLISH_SEPARATOR: String = "."


func test_amounts_below_ten_thousand_stay_exact() -> void:
	assert_eq(CoinAmountFormat.format_compact(0, FRENCH_SEPARATOR), "0")
	assert_eq(CoinAmountFormat.format_compact(9999, FRENCH_SEPARATOR), "9999")


func test_thousands_keep_one_decimal_below_a_hundred() -> void:
	assert_eq(CoinAmountFormat.format_compact(10000, FRENCH_SEPARATOR), "10k")
	assert_eq(CoinAmountFormat.format_compact(12500, FRENCH_SEPARATOR), "12,5k")
	assert_eq(CoinAmountFormat.format_compact(99999, FRENCH_SEPARATOR), "99,9k")


func test_hundreds_of_thousands_have_no_decimal() -> void:
	assert_eq(CoinAmountFormat.format_compact(100000, FRENCH_SEPARATOR), "100k")
	assert_eq(CoinAmountFormat.format_compact(999999, FRENCH_SEPARATOR), "999k")


func test_millions_keep_one_decimal_below_ten() -> void:
	assert_eq(CoinAmountFormat.format_compact(1000000, FRENCH_SEPARATOR), "1M")
	assert_eq(CoinAmountFormat.format_compact(1250000, FRENCH_SEPARATOR), "1,2M")
	assert_eq(CoinAmountFormat.format_compact(9999999, FRENCH_SEPARATOR), "9,9M")
	assert_eq(CoinAmountFormat.format_compact(12345678, FRENCH_SEPARATOR), "12M")


func test_a_negative_amount_shows_zero() -> void:
	assert_eq(CoinAmountFormat.format_compact(-5, FRENCH_SEPARATOR), "0")


func test_the_decimal_separator_follows_the_language() -> void:
	assert_eq(CoinAmountFormat.format_compact(12500, ENGLISH_SEPARATOR), "12.5k")
	assert_eq(CoinAmountFormat.format_compact(1250000, ENGLISH_SEPARATOR), "1.2M")
