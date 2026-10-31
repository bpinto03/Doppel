class_name UiThemeBuilder
extends RefCounted

## Builds the interface Theme of a palette on top of the base theme (font, sizes).

const CORNER_RADIUS: int = 24
const PRESSED_DARKENING: float = 0.15
const DISABLED_OPACITY: float = 0.4
const BUTTON_FONT_STATES: Array[StringName] = [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_hover_pressed_color"]
## Settings toggles and choices: outlined when off, filled like a button when on.
const CHOICE_BUTTON_TYPE: StringName = &"ChoiceButton"
const CHOICE_BORDER_WIDTH: int = 4
const CHOICE_OFF_FONT_STATES: Array[StringName] = [&"font_color", &"font_hover_color", &"font_focus_color"]
const CHOICE_ON_FONT_STATES: Array[StringName] = [&"font_pressed_color", &"font_hover_pressed_color"]


static func build(palette: ThemePalette, base_theme: Theme) -> Theme:
	var theme: Theme = base_theme.duplicate()
	theme.set_color(&"font_color", &"Label", palette.text)
	theme.set_stylebox(&"panel", &"PanelContainer", _create_rounded_box(palette.panel))
	_add_button_styles(theme, palette)
	_add_choice_button_styles(theme, palette)
	return theme


static func _add_button_styles(theme: Theme, palette: ThemePalette) -> void:
	for state: StringName in BUTTON_FONT_STATES:
		theme.set_color(state, &"Button", palette.button_text)
	theme.set_color(&"font_disabled_color", &"Button", Color(palette.button_text, DISABLED_OPACITY))
	theme.set_stylebox(&"normal", &"Button", _create_rounded_box(palette.button))
	theme.set_stylebox(&"hover", &"Button", _create_rounded_box(palette.button))
	theme.set_stylebox(&"pressed", &"Button", _create_rounded_box(palette.button.darkened(PRESSED_DARKENING)))
	theme.set_stylebox(&"disabled", &"Button", _create_rounded_box(Color(palette.button, DISABLED_OPACITY)))
	theme.set_stylebox(&"focus", &"Button", StyleBoxEmpty.new())


static func _add_choice_button_styles(theme: Theme, palette: ThemePalette) -> void:
	theme.set_type_variation(CHOICE_BUTTON_TYPE, &"Button")
	for state: StringName in CHOICE_OFF_FONT_STATES:
		theme.set_color(state, CHOICE_BUTTON_TYPE, palette.text)
	for state: StringName in CHOICE_ON_FONT_STATES:
		theme.set_color(state, CHOICE_BUTTON_TYPE, palette.button_text)
	var off_box: StyleBoxFlat = _create_rounded_box(palette.panel)
	off_box.border_color = palette.button
	off_box.set_border_width_all(CHOICE_BORDER_WIDTH)
	theme.set_stylebox(&"normal", CHOICE_BUTTON_TYPE, off_box)
	theme.set_stylebox(&"hover", CHOICE_BUTTON_TYPE, off_box)
	theme.set_stylebox(&"pressed", CHOICE_BUTTON_TYPE, _create_rounded_box(palette.button))
	theme.set_stylebox(&"hover_pressed", CHOICE_BUTTON_TYPE, _create_rounded_box(palette.button))


static func _create_rounded_box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(CORNER_RADIUS)
	return box
