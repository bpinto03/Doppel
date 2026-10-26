extends Node

## Applies the language chosen in Settings, or the device language when it is supported.

const SUPPORTED_LANGUAGES: Array[String] = ["en", "fr"]
const FALLBACK_LANGUAGE: String = "en"


func _ready() -> void:
	Settings.changed.connect(apply_language)
	apply_language()


func apply_language() -> void:
	TranslationServer.set_locale(resolve_language(Settings.language, OS.get_locale_language()))


static func resolve_language(chosen_language: String, device_language: String) -> String:
	if SUPPORTED_LANGUAGES.has(chosen_language):
		return chosen_language
	if SUPPORTED_LANGUAGES.has(device_language):
		return device_language
	return FALLBACK_LANGUAGE
