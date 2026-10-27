class_name ComboText
extends RefCounted

## Texts of the combo message, in the current language.


static func format_multiplier(multiplier: float) -> String:
	var value: String = String.num(multiplier, 1).trim_suffix(".0").replace(".", TranslationServer.translate("UI_DECIMAL_SEPARATOR"))
	return TranslationServer.translate("UI_CHAIN_MULTIPLIER").format({"value": value})


static func build(chain_link: int, multiplier: float, config: ResolutionPlaybackConfig) -> String:
	var word_key: String = config.get_combo_word_key(chain_link)
	if word_key.is_empty():
		return format_multiplier(multiplier)
	return TranslationServer.translate("UI_COMBO_WITH_WORD").format({"word": TranslationServer.translate(word_key), "multiplier": format_multiplier(multiplier)})
