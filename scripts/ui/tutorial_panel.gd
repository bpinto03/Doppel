class_name TutorialPanel
extends PanelContainer

signal next_requested
signal skip_requested

@onready var _message_label: Label = %MessageLabel
@onready var _next_button: Button = %NextButton
@onready var _skip_button: Button = %SkipButton


func _ready() -> void:
	_next_button.pressed.connect(next_requested.emit)
	_skip_button.pressed.connect(skip_requested.emit)


func show_instruction(text_key: StringName) -> void:
	_message_label.text = tr(text_key)
	_next_button.visible = false
	visible = true


func show_explanation(text_key: StringName, is_last_step: bool) -> void:
	_message_label.text = tr(text_key)
	_next_button.text = tr(&"TUTORIAL_DONE") if is_last_step else tr(&"TUTORIAL_NEXT")
	_next_button.visible = true
	visible = true


func is_waiting_for_next() -> bool:
	return visible and _next_button.visible
