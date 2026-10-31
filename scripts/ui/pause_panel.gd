class_name PausePanel
extends Control

## Covers the paused game: Resume, Restart (abandons the game) and Menu (keeps it to continue).

signal resume_requested
signal restart_requested
signal menu_requested

@onready var _resume_button: Button = %ResumeButton
@onready var _restart_button: Button = %RestartButton
@onready var _menu_button: Button = %MenuButton


func _ready() -> void:
	_resume_button.pressed.connect(resume_requested.emit)
	_restart_button.pressed.connect(restart_requested.emit)
	_menu_button.pressed.connect(menu_requested.emit)
