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
const BOLD_FONT: Font = preload("res://assets/fonts/fredoka_bold.ttf")
const HUD_ROW_SEPARATION: int = 32
const HUD_CAPSULE_RADIUS: int = 40
const HUD_PANEL_RADIUS: int = 28
const HUD_BORDER_WIDTH: int = 3
const HUD_SCORE_PANEL_BORDER_WIDTH: int = 2
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
## Shortens the separator at both ends, so it spans about half of the capsule height.
const HUD_SEPARATOR_INSET: float = 44.0
const HUD_CAPTION_FONT_SIZE: int = 32
const HUD_VALUE_FONT_SIZE: int = 60
## Label shadows cannot blur: a thin, faint outline reads as a halo rather than a stroke.
const HUD_VALUE_GLOW_SIZE: int = 6
const PAUSE_BUTTON_RADIUS: int = 26
const PAUSE_BUTTON_BORDER_WIDTH: int = 3
const HOME_TITLE_TYPE: StringName = &"HomeTitle"
const HOME_TITLE_FONT_SIZE: int = 168
## Glow of the home and pause titles.
const TITLE_GLOW_SIZE: int = 12
const HOME_PRIMARY_BUTTON_TYPE: StringName = &"HomePrimaryButton"
const HOME_SECONDARY_BUTTON_TYPE: StringName = &"HomeSecondaryButton"
## Every IconActionButton variation: home, pause, game over and tutorial buttons.
const ICON_BUTTON_RADIUS: int = 36
const ICON_BUTTON_BORDER_WIDTH: int = 3
const ICON_BUTTON_FONT_SIZE: int = 44
## Pause overlay: scrim, panel, title between two rules, then its buttons.
const MODAL_SCRIM_TYPE: StringName = &"ModalScrim"
const MODAL_CARD_TYPE: StringName = &"ModalCard"
const MODAL_TITLE_TYPE: StringName = &"ModalTitle"
const MODAL_TITLE_RULE_TYPE: StringName = &"ModalTitleRule"
const MODAL_PRIMARY_BUTTON_TYPE: StringName = &"ModalPrimaryButton"
const MODAL_SECONDARY_BUTTON_TYPE: StringName = &"ModalSecondaryButton"
const MODAL_CARD_RADIUS: int = 56
const MODAL_CARD_BORDER_WIDTH: int = 3
const MODAL_CARD_PADDING: int = 56
const MODAL_TITLE_FONT_SIZE: int = 104
const MODAL_TITLE_RULE_WIDTH: int = 3
## Game over overlay: a smaller title, so "Partie terminée" fits, and three tinted stat rows.
const GAME_OVER_TITLE_TYPE: StringName = &"GameOverTitle"
const GAME_OVER_SCORE_ROW_TYPE: StringName = &"GameOverScoreRow"
const GAME_OVER_RECORD_ROW_TYPE: StringName = &"GameOverRecordRow"
const GAME_OVER_TILE_ROW_TYPE: StringName = &"GameOverTileRow"
const GAME_OVER_STAT_CAPTION_TYPE: StringName = &"GameOverStatCaption"
const GAME_OVER_RECORD_CAPTION_TYPE: StringName = &"GameOverRecordCaption"
const GAME_OVER_STAT_VALUE_TYPE: StringName = &"GameOverStatValue"
const GAME_OVER_TITLE_FONT_SIZE: int = 84
const STAT_ROW_RADIUS: int = 28
const STAT_ROW_BORDER_WIDTH: int = 2
const STAT_ROW_HORIZONTAL_MARGIN: int = 32
const STAT_ROW_VERTICAL_MARGIN: int = 14
const STAT_CAPTION_FONT_SIZE: int = 40
const STAT_VALUE_FONT_SIZE: int = 60
## Tutorial panel under the board: the modal card with less padding, and its message.
const TUTORIAL_CARD_TYPE: StringName = &"TutorialCard"
const TUTORIAL_MESSAGE_TYPE: StringName = &"TutorialMessage"
const TUTORIAL_CARD_PADDING: int = 36
const TUTORIAL_MESSAGE_FONT_SIZE: int = 44
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
	_add_home_button_styles(theme, palette)
	_add_glowing_label_style(theme, HOME_TITLE_TYPE, HOME_TITLE_FONT_SIZE, palette.title, palette.title_glow, TITLE_GLOW_SIZE)
	_add_modal_styles(theme, palette)
	_add_game_over_styles(theme, palette)
	_add_tutorial_styles(theme, palette)
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
	_add_hud_value_style(theme, HUD_SCORE_VALUE_TYPE, palette.text, palette.score_value_glow)
	_add_hud_value_style(theme, HUD_RECORD_VALUE_TYPE, palette.text, palette.record_value_glow)
	_add_pause_button_styles(theme, palette)


static func _add_hud_capsule_style(theme: Theme, palette: ThemePalette) -> void:
	theme.set_type_variation(HUD_CAPSULE_TYPE, &"PanelContainer")
	var box: StyleBoxFlat = _create_bordered_box(palette.hud_capsule, palette.hud_capsule_border, HUD_BORDER_WIDTH, HUD_CAPSULE_RADIUS)
	_add_glow(box, palette.hud_capsule_glow)
	theme.set_stylebox(&"panel", HUD_CAPSULE_TYPE, box)
	theme.set_type_variation(HUD_SCORE_MARGIN_TYPE, &"MarginContainer")
	for side: StringName in [&"margin_left", &"margin_top", &"margin_bottom"]:
		theme.set_constant(side, HUD_SCORE_MARGIN_TYPE, HUD_CAPSULE_INSET)


static func _add_hud_score_panel_style(theme: Theme, palette: ThemePalette) -> void:
	theme.set_type_variation(HUD_SCORE_PANEL_TYPE, &"PanelContainer")
	var box: StyleBoxFlat = _create_bordered_box(palette.hud_panel, palette.hud_score_panel_border, HUD_SCORE_PANEL_BORDER_WIDTH, HUD_PANEL_RADIUS)
	_set_content_margins(box, HUD_PANEL_HORIZONTAL_MARGIN, HUD_PANEL_VERTICAL_MARGIN)
	theme.set_stylebox(&"panel", HUD_SCORE_PANEL_TYPE, box)


## Same corners as the capsule: its border covers the capsule border on the right.
static func _add_hud_record_panel_style(theme: Theme, palette: ThemePalette) -> void:
	theme.set_type_variation(HUD_RECORD_PANEL_TYPE, &"PanelContainer")
	var box: StyleBoxFlat = _create_bordered_box(palette.hud_panel, palette.hud_record_panel_border, HUD_BORDER_WIDTH, HUD_CAPSULE_RADIUS)
	_set_content_margins(box, HUD_PANEL_HORIZONTAL_MARGIN, HUD_RECORD_PANEL_VERTICAL_MARGIN)
	_add_glow(box, palette.hud_record_panel_glow)
	theme.set_stylebox(&"panel", HUD_RECORD_PANEL_TYPE, box)


static func _add_hud_separator_style(theme: Theme, palette: ThemePalette) -> void:
	theme.set_type_variation(HUD_SEPARATOR_TYPE, &"VSeparator")
	var line := StyleBoxLine.new()
	line.vertical = true
	line.color = palette.hud_separator
	line.thickness = HUD_SEPARATOR_WIDTH
	line.grow_begin = -HUD_SEPARATOR_INSET
	line.grow_end = -HUD_SEPARATOR_INSET
	theme.set_stylebox(&"separator", HUD_SEPARATOR_TYPE, line)
	theme.set_constant(&"separation", HUD_SEPARATOR_TYPE, HUD_SEPARATOR_SPACE)


static func _add_hud_caption_style(theme: Theme, type: StringName, color: Color) -> void:
	theme.set_type_variation(type, &"Label")
	theme.set_color(&"font_color", type, color)
	theme.set_font_size(&"font_size", type, HUD_CAPTION_FONT_SIZE)


static func _add_hud_value_style(theme: Theme, type: StringName, color: Color, glow_color: Color) -> void:
	_add_glowing_label_style(theme, type, HUD_VALUE_FONT_SIZE, color, glow_color, HUD_VALUE_GLOW_SIZE)


## Bold text whose glow is the label shadow, centered and widened by its outline; a transparent color removes it.
static func _add_glowing_label_style(theme: Theme, type: StringName, font_size: int, color: Color, glow_color: Color, glow_size: int) -> void:
	theme.set_type_variation(type, &"Label")
	theme.set_font(&"font", type, BOLD_FONT)
	theme.set_font_size(&"font_size", type, font_size)
	theme.set_color(&"font_color", type, color)
	theme.set_color(&"font_shadow_color", type, glow_color)
	theme.set_constant(&"shadow_offset_x", type, 0)
	theme.set_constant(&"shadow_offset_y", type, 0)
	theme.set_constant(&"shadow_outline_size", type, glow_size if glow_color.a > 0.0 else 0)


## The pause symbol is drawn by PauseButton in the font color.
static func _add_pause_button_styles(theme: Theme, palette: ThemePalette) -> void:
	theme.set_type_variation(PAUSE_BUTTON_TYPE, &"Button")
	for state: StringName in BUTTON_FONT_STATES:
		theme.set_color(state, PAUSE_BUTTON_TYPE, palette.pause_symbol)
	var normal_box: StyleBoxFlat = _create_bordered_box(palette.pause_button, palette.pause_button_border, PAUSE_BUTTON_BORDER_WIDTH, PAUSE_BUTTON_RADIUS)
	var pressed_box: StyleBoxFlat = normal_box.duplicate()
	pressed_box.bg_color = palette.pause_button.darkened(PRESSED_DARKENING)
	theme.set_stylebox(&"normal", PAUSE_BUTTON_TYPE, normal_box)
	theme.set_stylebox(&"hover", PAUSE_BUTTON_TYPE, normal_box)
	theme.set_stylebox(&"pressed", PAUSE_BUTTON_TYPE, pressed_box)
	theme.set_stylebox(&"hover_pressed", PAUSE_BUTTON_TYPE, pressed_box)
	theme.set_stylebox(&"focus", PAUSE_BUTTON_TYPE, StyleBoxEmpty.new())


static func _add_preview_styles(theme: Theme) -> void:
	theme.set_type_variation(PREVIEW_COLUMN_TYPE, &"VBoxContainer")
	theme.set_constant(&"separation", PREVIEW_COLUMN_TYPE, PREVIEW_CAPTION_SPACE)
	theme.set_type_variation(PREVIEW_CAPTION_TYPE, &"Label")
	theme.set_font(&"font", PREVIEW_CAPTION_TYPE, BOLD_FONT)
	theme.set_font_size(&"font_size", PREVIEW_CAPTION_TYPE, PREVIEW_CAPTION_FONT_SIZE)


static func _add_home_button_styles(theme: Theme, palette: ThemePalette) -> void:
	_add_icon_button_box(theme, HOME_PRIMARY_BUTTON_TYPE, palette.home_primary_button, palette.home_primary_button_border, palette.home_primary_button_glow)
	_add_icon_button_badge(theme, HOME_PRIMARY_BUTTON_TYPE, palette.home_primary_badge, palette.home_primary_icon, palette.home_primary_text)
	_add_icon_button_box(theme, HOME_SECONDARY_BUTTON_TYPE, palette.home_secondary_button, palette.home_secondary_button_border, Color.TRANSPARENT)
	_add_icon_button_badge(theme, HOME_SECONDARY_BUTTON_TYPE, palette.home_secondary_badge, palette.home_secondary_icon, palette.home_secondary_text)


static func _add_modal_styles(theme: Theme, palette: ThemePalette) -> void:
	theme.set_type_variation(MODAL_SCRIM_TYPE, &"Panel")
	var scrim_box := StyleBoxFlat.new()
	scrim_box.bg_color = palette.modal_scrim
	theme.set_stylebox(&"panel", MODAL_SCRIM_TYPE, scrim_box)
	theme.set_type_variation(MODAL_CARD_TYPE, &"PanelContainer")
	var card_box: StyleBoxFlat = _create_bordered_box(palette.modal_panel, palette.modal_panel_border, MODAL_CARD_BORDER_WIDTH, MODAL_CARD_RADIUS)
	_set_content_margins(card_box, MODAL_CARD_PADDING, MODAL_CARD_PADDING)
	_add_glow(card_box, palette.modal_panel_glow)
	theme.set_stylebox(&"panel", MODAL_CARD_TYPE, card_box)
	_add_glowing_label_style(theme, MODAL_TITLE_TYPE, MODAL_TITLE_FONT_SIZE, palette.title, palette.title_glow, TITLE_GLOW_SIZE)
	theme.set_type_variation(MODAL_TITLE_RULE_TYPE, &"HSeparator")
	var rule := StyleBoxLine.new()
	rule.color = palette.modal_title_rule
	rule.thickness = MODAL_TITLE_RULE_WIDTH
	theme.set_stylebox(&"separator", MODAL_TITLE_RULE_TYPE, rule)
	theme.set_constant(&"separation", MODAL_TITLE_RULE_TYPE, MODAL_TITLE_RULE_WIDTH)
	_add_icon_button_box(theme, MODAL_PRIMARY_BUTTON_TYPE, palette.modal_primary_button, palette.modal_primary_button_border, palette.modal_primary_button_glow)
	_add_icon_button_badge(theme, MODAL_PRIMARY_BUTTON_TYPE, palette.modal_primary_badge, palette.modal_primary_icon, palette.modal_primary_text)
	_add_icon_button_box(theme, MODAL_SECONDARY_BUTTON_TYPE, palette.modal_secondary_button, palette.modal_secondary_button_border, Color.TRANSPARENT)
	_add_icon_button_badge(theme, MODAL_SECONDARY_BUTTON_TYPE, palette.modal_secondary_badge, palette.modal_secondary_icon, palette.modal_secondary_text)


## Hover looks like normal, since a tap on Android can leave a button hovered; a tap never shows a focus frame.
static func _add_game_over_styles(theme: Theme, palette: ThemePalette) -> void:
	theme.set_type_variation(GAME_OVER_TITLE_TYPE, MODAL_TITLE_TYPE)
	theme.set_font_size(&"font_size", GAME_OVER_TITLE_TYPE, GAME_OVER_TITLE_FONT_SIZE)
	_add_stat_row_style(theme, GAME_OVER_SCORE_ROW_TYPE, palette.game_over_score_row, palette.game_over_score_row_border, palette.game_over_score_row_glow)
	_add_stat_row_style(theme, GAME_OVER_RECORD_ROW_TYPE, palette.game_over_record_row, palette.game_over_record_row_border, palette.game_over_record_row_glow)
	_add_stat_row_style(theme, GAME_OVER_TILE_ROW_TYPE, palette.game_over_tile_row, palette.game_over_tile_row_border, palette.game_over_tile_row_glow)
	theme.set_type_variation(GAME_OVER_STAT_CAPTION_TYPE, &"Label")
	theme.set_font_size(&"font_size", GAME_OVER_STAT_CAPTION_TYPE, STAT_CAPTION_FONT_SIZE)
	theme.set_color(&"font_color", GAME_OVER_STAT_CAPTION_TYPE, palette.game_over_stat_caption)
	theme.set_type_variation(GAME_OVER_RECORD_CAPTION_TYPE, GAME_OVER_STAT_CAPTION_TYPE)
	theme.set_color(&"font_color", GAME_OVER_RECORD_CAPTION_TYPE, palette.game_over_record_caption)
	_add_glowing_label_style(theme, GAME_OVER_STAT_VALUE_TYPE, STAT_VALUE_FONT_SIZE, palette.game_over_stat_value, Color.TRANSPARENT, 0)


static func _add_tutorial_styles(theme: Theme, palette: ThemePalette) -> void:
	theme.set_type_variation(TUTORIAL_CARD_TYPE, MODAL_CARD_TYPE)
	var card_box: StyleBoxFlat = theme.get_stylebox(&"panel", MODAL_CARD_TYPE).duplicate()
	_set_content_margins(card_box, TUTORIAL_CARD_PADDING, TUTORIAL_CARD_PADDING)
	theme.set_stylebox(&"panel", TUTORIAL_CARD_TYPE, card_box)
	theme.set_type_variation(TUTORIAL_MESSAGE_TYPE, &"Label")
	theme.set_font_size(&"font_size", TUTORIAL_MESSAGE_TYPE, TUTORIAL_MESSAGE_FONT_SIZE)
	theme.set_color(&"font_color", TUTORIAL_MESSAGE_TYPE, palette.modal_secondary_text)


static func _add_stat_row_style(theme: Theme, type: StringName, color: Color, border_color: Color, glow_color: Color) -> void:
	theme.set_type_variation(type, &"PanelContainer")
	var box: StyleBoxFlat = _create_bordered_box(color, border_color, STAT_ROW_BORDER_WIDTH, STAT_ROW_RADIUS)
	_set_content_margins(box, STAT_ROW_HORIZONTAL_MARGIN, STAT_ROW_VERTICAL_MARGIN)
	_add_glow(box, glow_color)
	theme.set_stylebox(&"panel", type, box)


static func _add_icon_button_box(theme: Theme, type: StringName, color: Color, border_color: Color, glow_color: Color) -> void:
	theme.set_type_variation(type, &"Button")
	theme.set_font_size(&"font_size", type, ICON_BUTTON_FONT_SIZE)
	var normal_box: StyleBoxFlat = _create_bordered_box(color, border_color, ICON_BUTTON_BORDER_WIDTH, ICON_BUTTON_RADIUS)
	_add_glow(normal_box, glow_color)
	normal_box.content_margin_left = IconActionButton.TEXT_LEFT_MARGIN
	normal_box.content_margin_right = IconActionButton.TEXT_RIGHT_MARGIN
	var pressed_box: StyleBoxFlat = normal_box.duplicate()
	pressed_box.bg_color = color.darkened(PRESSED_DARKENING)
	theme.set_stylebox(&"normal", type, normal_box)
	theme.set_stylebox(&"hover", type, normal_box)
	theme.set_stylebox(&"pressed", type, pressed_box)
	theme.set_stylebox(&"hover_pressed", type, pressed_box)
	theme.set_stylebox(&"focus", type, StyleBoxEmpty.new())


static func _add_icon_button_badge(theme: Theme, type: StringName, badge_color: Color, icon_color: Color, text_color: Color) -> void:
	for state: StringName in BUTTON_FONT_STATES:
		theme.set_color(state, type, text_color)
	var badge_box := StyleBoxFlat.new()
	badge_box.bg_color = badge_color
	badge_box.set_corner_radius_all(ceili(IconActionButton.BADGE_SIZE / 2.0))
	theme.set_stylebox(&"badge", type, badge_box)
	theme.set_color(&"badge_icon_color", type, icon_color)


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


## A glow is a shadow without offset; a transparent color removes it.
static func _add_glow(box: StyleBoxFlat, color: Color) -> void:
	box.shadow_color = color
	box.shadow_size = HUD_GLOW_SIZE if color.a > 0.0 else 0


static func _create_rounded_box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(CORNER_RADIUS)
	return box
