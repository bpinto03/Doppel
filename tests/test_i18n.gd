extends GutTest

const I18N_SCRIPT: GDScript = preload("res://scripts/autoload/i18n.gd")


func test_chosen_language_wins_over_device_language() -> void:
	assert_eq(I18N_SCRIPT.resolve_language("fr", "en"), "fr")


func test_supported_device_language_is_used_when_none_is_chosen() -> void:
	assert_eq(I18N_SCRIPT.resolve_language("", "fr"), "fr")


func test_unsupported_device_language_falls_back_to_english() -> void:
	assert_eq(I18N_SCRIPT.resolve_language("", "de"), "en")
