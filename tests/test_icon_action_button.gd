extends GutTest

const BUTTON_SCENE: PackedScene = preload("res://scenes/ui/icon_action_button.tscn")
const BASE_THEME: Theme = preload("res://assets/themes/base_theme.tres")
const VARIATIONS: Array[StringName] = [
	UiThemeBuilder.HOME_PRIMARY_BUTTON_TYPE, UiThemeBuilder.HOME_SECONDARY_BUTTON_TYPE,
	UiThemeBuilder.MODAL_PRIMARY_BUTTON_TYPE, UiThemeBuilder.MODAL_SECONDARY_BUTTON_TYPE,
]

var _button: IconActionButton


func before_each() -> void:
	_button = BUTTON_SCENE.instantiate()
	_button.text = "Continuer"
	add_child_autofree(_button)


func test_hover_looks_like_normal_and_focus_shows_nothing() -> void:
	for entry: ThemeEntry in Settings.THEME_CATALOG.get_entries():
		var palette: ThemePalette = entry.palette
		_button.theme = UiThemeBuilder.build(palette, BASE_THEME)
		for variation: StringName in VARIATIONS:
			_button.theme_type_variation = variation
			assert_eq(_button.get_theme_stylebox(&"hover"), _button.get_theme_stylebox(&"normal"), String(variation))
			assert_is(_button.get_theme_stylebox(&"focus"), StyleBoxEmpty, String(variation))


func test_minimum_width_counts_the_badge_and_the_chevron() -> void:
	_button.theme = UiThemeBuilder.build(Settings.THEME_CATALOG.find_entry(&"paper").palette, BASE_THEME)
	var font: Font = _button.get_theme_font(&"font")
	var text_width: float = font.get_string_size(_button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, _button.get_theme_font_size(&"font_size")).x

	var margins: float = IconActionButton.TEXT_LEFT_MARGIN + IconActionButton.TEXT_RIGHT_MARGIN
	assert_almost_eq(_button.get_combined_minimum_size().x, text_width + margins, 1.0)
