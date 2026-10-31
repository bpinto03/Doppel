class_name TutorialPanel
extends PanelContainer

## Under the board: a step's instruction beside a tap icon, with Skip; then its explanation, with Next and Skip,
## or Done alone on the last step, since Skip would do the same.
## The message keeps the height of the tallest text of the steps, so the board keeps the same room all along.

signal next_requested
signal skip_requested

const NEXT_ICON: Texture2D = preload("res://assets/icons/icon_next.svg")
const DONE_ICON: Texture2D = preload("res://assets/icons/icon_done.svg")
const HAND_ICON_SIZE := Vector2(104.0, 104.0)
const ICON_TEXT_GAP: int = 24
const MESSAGE_BUTTONS_GAP: int = 32
const BUTTON_HEIGHT: float = 140.0
const BUTTON_GAP: int = 24
## Same line breaking as the label's AUTOWRAP_WORD_SMART.
const WORD_SMART_BREAKS: int = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE

var _instruction_keys: Array[StringName] = []
var _explanation_keys: Array[StringName] = []

@onready var _content: VBoxContainer = %Content
@onready var _message_row: HBoxContainer = %MessageRow
@onready var _hand_icon: TextureRect = %HandIcon
@onready var _message_label: Label = %MessageLabel
@onready var _buttons: HBoxContainer = %Buttons
@onready var _skip_button: IconActionButton = %SkipButton
@onready var _next_button: IconActionButton = %NextButton


func _ready() -> void:
	_content.add_theme_constant_override(&"separation", MESSAGE_BUTTONS_GAP)
	_message_row.add_theme_constant_override(&"separation", ICON_TEXT_GAP)
	_buttons.add_theme_constant_override(&"separation", BUTTON_GAP)
	_hand_icon.custom_minimum_size = HAND_ICON_SIZE
	for button: Button in [_skip_button, _next_button]:
		button.custom_minimum_size.y = BUTTON_HEIGHT
	_next_button.pressed.connect(next_requested.emit)
	_skip_button.pressed.connect(skip_requested.emit)
	resized.connect(_fit_message_height)


func apply_palette(palette: ThemePalette) -> void:
	_hand_icon.self_modulate = palette.tutorial_icon


func fit_to_steps(steps: Array[TutorialStep]) -> void:
	_instruction_keys.clear()
	_explanation_keys.clear()
	for step: TutorialStep in steps:
		_instruction_keys.append(step.instruction_key)
		_explanation_keys.append(step.explanation_key)
	_fit_message_height()


func show_instruction(text_key: StringName) -> void:
	_message_label.text = tr(text_key)
	_hand_icon.visible = true
	_skip_button.visible = true
	_next_button.visible = false
	visible = true


func show_explanation(text_key: StringName, is_last_step: bool) -> void:
	_message_label.text = tr(text_key)
	_hand_icon.visible = false
	_skip_button.visible = not is_last_step
	_next_button.text = tr(&"TUTORIAL_DONE") if is_last_step else tr(&"TUTORIAL_NEXT")
	_next_button.badge_icon = DONE_ICON if is_last_step else NEXT_ICON
	_next_button.visible = true
	visible = true


func is_waiting_for_next() -> bool:
	return visible and _next_button.visible


## Instructions share their line with the icon, explanations get the whole width.
func _fit_message_height() -> void:
	var full_width: float = size.x - get_theme_stylebox(&"panel").get_minimum_size().x
	var instruction_width: float = full_width - HAND_ICON_SIZE.x - ICON_TEXT_GAP
	var tallest: float = HAND_ICON_SIZE.y
	for text_key: StringName in _instruction_keys:
		tallest = maxf(tallest, _measure_text_height(tr(text_key), instruction_width))
	for text_key: StringName in _explanation_keys:
		tallest = maxf(tallest, _measure_text_height(tr(text_key), full_width))
	_message_label.custom_minimum_size.y = ceilf(tallest)


func _measure_text_height(text: String, width: float) -> float:
	var paragraph := TextParagraph.new()
	paragraph.add_string(text, _message_label.get_theme_font(&"font"), _message_label.get_theme_font_size(&"font_size"))
	paragraph.width = width
	paragraph.break_flags = WORD_SMART_BREAKS
	var line_spacing: int = _message_label.get_theme_constant(&"line_spacing")
	return paragraph.get_size().y + line_spacing * paragraph.get_line_count()
