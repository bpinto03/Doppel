extends GutTest

var _player_locale: String


func before_each() -> void:
	_player_locale = TranslationServer.get_locale()


func after_each() -> void:
	TranslationServer.set_locale(_player_locale)


func test_multiplier_uses_the_english_decimal_point() -> void:
	TranslationServer.set_locale("en")

	assert_eq(ComboText.format_multiplier(2.5), "x2.5")
	assert_eq(ComboText.format_multiplier(3.0), "x3")


func test_multiplier_uses_the_french_decimal_comma() -> void:
	TranslationServer.set_locale("fr")

	assert_eq(ComboText.format_multiplier(2.5), "x2,5")
	assert_eq(ComboText.format_multiplier(3.0), "x3")
