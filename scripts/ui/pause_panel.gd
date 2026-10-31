class_name PausePanel
extends Control

## Covers the paused game. Main page: Menu (keeps the game to continue), Restart (abandons it), Settings and Resume.
## Settings page: the sound, music, vibration and screen shake toggles of SettingsRows, and Back to the main page.

signal resume_requested
signal restart_requested
signal menu_requested
## The Settings or Back button switched the page, for the click sound.
signal page_button_pressed

@onready var _main_page: Control = %MainPage
@onready var _settings_page: Control = %SettingsPage
@onready var _resume_button: Button = %ResumeButton
@onready var _restart_button: Button = %RestartButton
@onready var _menu_button: Button = %MenuButton
@onready var _settings_button: Button = %SettingsButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_resume_button.pressed.connect(resume_requested.emit)
	_restart_button.pressed.connect(restart_requested.emit)
	_menu_button.pressed.connect(menu_requested.emit)
	_settings_button.pressed.connect(show_settings_page)
	_back_button.pressed.connect(show_main_page)
	_settings_button.pressed.connect(page_button_pressed.emit)
	_back_button.pressed.connect(page_button_pressed.emit)


func show_main_page() -> void:
	_settings_page.visible = false
	_main_page.visible = true


func show_settings_page() -> void:
	_main_page.visible = false
	_settings_page.visible = true


func is_showing_settings() -> bool:
	return _settings_page.visible
