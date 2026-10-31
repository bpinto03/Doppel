class_name UiThemeBuilder
extends RefCounted

## Builds the interface Theme of a palette on top of the base theme (font, sizes).

const CORNER_RADIUS: int = 24
const PRESSED_DARKENING: float = 0.15
const DISABLED_OPACITY: float = 0.4
const BUTTON_FONT_STATES: Array[StringName] = [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_hover_pressed_color"]
## Secondary actions: outlined, filled like a button while pressed.
const SECONDARY_BUTTON_TYPE: StringName = &"SecondaryButton"
## Settings toggles and choices: a secondary button that stays filled while on.
const CHOICE_BUTTON_TYPE: StringName = &"ChoiceButton"
const SECONDARY_BORDER_WIDTH: int = 4
const OUTLINED_FONT_STATES: Array[StringName] = [&"font_color", &"font_hover_color", &"font_focus_color"]
const FILLED_FONT_STATES: Array[StringName] = [&"font_pressed_color", &"font_hover_pressed_color"]

## HUD above the board: a capsule holding the score panel, a separator and the record panel, then the pause button.
const HUD_ROW_TYPE: StringName = &"HudRow"
const HUD_CAPSULE_TYPE: StringName = &"HudCapsule"
const HUD_SCORE_MARGIN_TYPE: StringName = &"HudScoreMargin"
const HUD_SCORE_PANEL_TYPE: StringName = &"HudScorePanel"
const HUD_RECORD_PANEL_TYPE: StringName = &"HudRecordPanel"
const HUD_PANEL_ROW_TYPE: StringName = &"HudPanelRow"
const HUD_SEPARATOR_TYPE: StringName = &"HudSeparator"
const HUD_SCORE_CAPTION_TYPE: StringName = &"HudScoreCaption"
const HUD_RECORD_CAPTION_TYPE: StringName = &"HudRecordCaption"
const HUD_SCORE_VALUE_TYPE: StringName = &"HudScoreValue"
const HUD_RECORD_VALUE_TYPE: StringName = &"HudRecordValue"
const PAUSE_BUTTON_TYPE: StringName = &"PauseButton"
const HUD_VALUE_FONT: Font = preload("res://assets/fonts/fredoka_bold.ttf")
const HUD_ROW_SEPARATION: int = 32
const HUD_CAPSULE_RADIUS: int = 40
const HUD_PANEL_RADIUS: int = 28
const HUD_BORDER_WIDTH: int = 3
const HUD_SCORE_PANEL_BORDER_WIDTH: int = 2
## The score panel border is a faint version of the capsule border.
const HUD_SCORE_PANEL_BORDER_OPACITY: float = 0.4
const HUD_GLOW_SIZE: int = 12
## Space between the capsule border and the score panel.
const HUD_CAPSULE_INSET: int = 14
const HUD_PANEL_HORIZONTAL_MARGIN: int = 20
const HUD_PANEL_VERTICAL_MARGIN: int = 8
## The record panel touches the capsule edges, so its content needs the capsule inset to line up with the score.
const HUD_RECORD_PANEL_VERTICAL_MARGIN: int = HUD_CAPSULE_INSET + HUD_SCORE_PANEL_BORDER_WIDTH + HUD_PANEL_VERTICAL_MARGIN - HUD_BORDER_WIDTH
const HUD_PANEL_ROW_SEPARATION: int = 14
const HUD_SEPARATOR_WIDTH: int = 2
const HUD_SEPARATOR_SPACE: int = 40
const HUD_SEPARATOR_OPACITY: float = 0.2
## Shortens the separator at both ends, so it spans about half of the capsule height.
const HUD_SEPARATOR_INSET: float = 44.0
const HUD_CAPTION_FONT_SIZE: int = 32
const HUD_VALUE_FONT_SIZE: int = 60
const HUD_VALUE_GLOW_SIZE: int = 6
## Label shadows cannot blur: a fainter outline than the panel glows reads as a halo rather than a stroke.
const HUD_VALUE_GLOW_STRENGTH: float = 0.5
const PAUSE_BUTTON_RADIUS: int = 26
const PAUSE_BUTTON_BORDER_WIDTH: int = 3
## Tile, mirror and next previews under the HUD.
const PREVIEW_COLUMN_TYPE: StringName = &"PreviewColumn"
const PREVIEW_CAPTION_TYPE: StringName = &"PreviewCaption"
const PREVIEW_CAPTION_FONT_SIZE: int = 40
const PREVIEW_CAPTION_SPACE: int = 18


static func build(palette: ThemePalette, base_theme: Theme) -> Theme:
	var theme: Theme = base_theme.duplicate()
	theme.set_color(&"font_color", &"Label", palette.text)
	theme.set_stylebox(&"panel", &"PanelContainer", _create_rounded_box(palette.panel))
	_add_button_styles(theme, palette)
	_add_secondary_button_styles(theme, palette)
	_add_hud_styles(theme, palette)
	_add_preview_styles(theme)
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


static func _add_secondary_button_styles(theme: Theme, palette: ThemePalette) -> void:
	theme.set_type_variation(SECONDARY_BUTTON_TYPE, &"Button")
	theme.set_type_variation(CHOICE_BUTTON_TYPE, SECONDARY_BUTTON_TYPE)
	for state: StringName in OUTLINED_FONT_STATES:
		theme.set_color(state, SECONDARY_BUTTON_TYPE, palette.text)
	for state: StringName in FILLED_FONT_STATES:
		theme.set_color(state, SECONDARY_BUTTON_TYPE, palette.button_text)
	var outlined_box: StyleBoxFlat = _create_rounded_box(palette.panel)
	outlined_box.border_color = palette.button
	outlined_box.set_border_width_all(SECONDARY_BORDER_WIDTH)
	theme.set_stylebox(&"normal", SECONDARY_BUTTON_TYPE, outlined_box)
	theme.set_stylebox(&"hover", SECONDARY_BUTTON_TYPE, outlined_box)
	theme.set_stylebox(&"pressed", SECONDARY_BUTTON_TYPE, _create_rounded_box(palette.button))
	theme.set_stylebox(&"hover_pressed", SECONDARY_BUTTON_TYPE, _create_rounded_box(palette.button))
	theme.set_stylebox(&"focus", SECONDARY_BUTTON_TYPE, StyleBoxEmpty.new())


static func _add_hud_styles(theme: Theme, palette: ThemePalette) -> void:
	theme.set_type_variation(HUD_ROW_TYPE, &"HBoxContainer")
	theme.set_constant(&"separation", HUD_ROW_TYPE, HUD_ROW_SEPARATION)
	theme.set_type_variation(HUD_PANEL_ROW_TYPE, &"HBoxContainer")
	theme.set_constant(&"separation", HUD_PANEL_ROW_TYPE, HUD_PANEL_ROW_SEPARATION)
	_add_hud_capsule_style(theme, palette)
	_add_hud_score_panel_style(theme, palette)
	_add_hud_record_panel_style(theme, palette)
	_add_hud_separator_style(theme, palette)
	_add_hud_caption_style(theme, HUD_SCORE_CAPTION_TYPE, palette.score_caption)
	_add_hud_caption_style(theme, HUD_RECORD_CAPTION_TYPE, palette.record_caption)
	_add_hud_value_style(theme, HUD_SCORE_VALUE_TYPE, palette, palette.score_accent)
	_add_hud_value_style(theme, HUD_RECORD_VALUE_TYPE, palette, palette.record_accent)
	_add_pause_button_styles(theme, palette)


static func _add_hud_capsule_style(theme: Theme, palette: ThemePalette) -> void:
	theme.set_type_variation(HUD_CAPSULE_TYPE, &"PanelContainer")
	var box: StyleBoxFlat = _create_bordered_box(palette.hud_capsule, palette.score_accent, HUD_BORDER_WIDTH, HUD_CAPSULE_RADIUS)
	_add_glow(box, palette.score_accent, palette.glow_opacity)
	theme.set_stylebox(&"panel", HUD_CAPSULE_TYPE, box)
	theme.set_type_variation(HUD_SCORE_MARGIN_TYPE, &"MarginContainer")
	for side: StringName in [&"margin_left", &"margin_top", &"margin_bottom"]:
		theme.set_constant(side, HUD_SCORE_MARGIN_TYPE, HUD_CAPSULE_INSET)


static func _add_hud_score_panel_style(theme: Theme, palette: ThemePalette) -> void:
	theme.set_type_variation(HUD_SCORE_PANEL_TYPE, &"PanelContainer")
	var border_color := Color(palette.score_accent, HUD_SCORE_PANEL_BORDER_OPACITY)
	var box: StyleBoxFlat = _create_bordered_box(palette.hud_panel, border_color, HUD_SCORE_PANEL_BORDER_WIDTH, HUD_PANEL_RADIUS)
	_set_content_margins(box, HUD_PANEL_HORIZONTAL_MARGIN, HUD_PANEL_VERTICAL_MARGIN)
	theme.set_stylebox(&"panel", HUD_SCORE_PANEL_TYPE, box)


## Same corners as the capsule: its violet border covers the capsule border on the right.
static func _add_hud_record_panel_style(theme: Theme, palette: ThemePalette) -> void:
	theme.set_type_variation(HUD_RECORD_PANEL_TYPE, &"PanelContainer")
	var box: StyleBoxFlat = _create_bordered_box(palette.hud_panel, palette.record_accent, HUD_BORDER_WIDTH, HUD_CAPSULE_RADIUS)
	_set_content_margins(box, HUD_PANEL_HORIZONTAL_MARGIN, HUD_RECORD_PANEL_VERTICAL_MARGIN)
	_add_glow(box, palette.record_accent, palette.glow_opacity)
	theme.set_stylebox(&"panel", HUD_RECORD_PANEL_TYPE, box)


static func _add_hud_separator_style(theme: Theme, palette: ThemePalette) -> void:
	theme.set_type_variation(HUD_SEPARATOR_TYPE, &"VSeparator")
	var line := StyleBoxLine.new()
	line.vertical = true
	line.color = Color(palette.text, HUD_SEPARATOR_OPACITY)
	line.thickness = HUD_SEPARATOR_WIDTH
	line.grow_begin = -HUD_SEPARATOR_INSET
	line.grow_end = -HUD_SEPARATOR_INSET
	theme.set_stylebox(&"separator", HUD_SEPARATOR_TYPE, line)
	theme.set_constant(&"separation", HUD_SEPARATOR_TYPE, HUD_SEPARATOR_SPACE)


static func _add_hud_caption_style(theme: Theme, type: StringName, color: Color) -> void:
	theme.set_type_variation(type, &"Label")
	theme.set_color(&"font_color", type, color)
	theme.set_font_size(&"font_size", type, HUD_CAPTION_FONT_SIZE)


## The glow is the label shadow, centered and widened by its outline.
static func _add_hud_value_style(theme: Theme, type: StringName, palette: ThemePalette, glow_color: Color) -> void:
	theme.set_type_variation(type, &"Label")
	theme.set_font(&"font", type, HUD_VALUE_FONT)
	theme.set_font_size(&"font_size", type, HUD_VALUE_FONT_SIZE)
	theme.set_color(&"font_color", type, palette.text)
	theme.set_color(&"font_shadow_color", type, Color(glow_color, palette.glow_opacity * HUD_VALUE_GLOW_STRENGTH))
	theme.set_constant(&"shadow_offset_x", type, 0)
	theme.set_constant(&"shadow_offset_y", type, 0)
	theme.set_constant(&"shadow_outline_size", type, HUD_VALUE_GLOW_SIZE)


## The pause symbol is drawn by PauseButton in the font color.
static func _add_pause_button_styles(theme: Theme, palette: ThemePalette) -> void:
	theme.set_type_variation(PAUSE_BUTTON_TYPE, &"Button")
	for state: StringName in BUTTON_FONT_STATES:
		theme.set_color(state, PAUSE_BUTTON_TYPE, palette.text)
	var normal_box: StyleBoxFlat = _create_bordered_box(palette.hud_panel, palette.panel_border, PAUSE_BUTTON_BORDER_WIDTH, PAUSE_BUTTON_RADIUS)
	var pressed_box: StyleBoxFlat = normal_box.duplicate()
	pressed_box.bg_color = palette.hud_panel.darkened(PRESSED_DARKENING)
	theme.set_stylebox(&"normal", PAUSE_BUTTON_TYPE, normal_box)
	theme.set_stylebox(&"hover", PAUSE_BUTTON_TYPE, normal_box)
	theme.set_stylebox(&"pressed", PAUSE_BUTTON_TYPE, pressed_box)
	theme.set_stylebox(&"hover_pressed", PAUSE_BUTTON_TYPE, pressed_box)
	theme.set_stylebox(&"focus", PAUSE_BUTTON_TYPE, StyleBoxEmpty.new())


static func _add_preview_styles(theme: Theme) -> void:
	theme.set_type_variation(PREVIEW_COLUMN_TYPE, &"VBoxContainer")
	theme.set_constant(&"separation", PREVIEW_COLUMN_TYPE, PREVIEW_CAPTION_SPACE)
	theme.set_type_variation(PREVIEW_CAPTION_TYPE, &"Label")
	theme.set_font(&"font", PREVIEW_CAPTION_TYPE, HUD_VALUE_FONT)
	theme.set_font_size(&"font_size", PREVIEW_CAPTION_TYPE, PREVIEW_CAPTION_FONT_SIZE)


static func _create_bordered_box(color: Color, border_color: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = _create_rounded_box(color)
	box.border_color = border_color
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(corner_radius)
	return box


static func _set_content_margins(box: StyleBox, horizontal: float, vertical: float) -> void:
	for side: Side in [SIDE_LEFT, SIDE_RIGHT]:
		box.set_content_margin(side, horizontal)
	for side: Side in [SIDE_TOP, SIDE_BOTTOM]:
		box.set_content_margin(side, vertical)


## A glow is a shadow in the border color, without offset; an opacity of 0 removes it.
static func _add_glow(box: StyleBoxFlat, color: Color, opacity: float) -> void:
	box.shadow_color = Color(color, opacity)
	box.shadow_size = HUD_GLOW_SIZE if opacity > 0.0 else 0


static func _create_rounded_box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(CORNER_RADIUS)
	return box
