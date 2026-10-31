class_name PausePanel
extends Control

## Covers the paused game. Main page: Resume, Menu (keeps the game to continue), Restart (abandons it) and Settings.
## Settings page: the sound, music, vibration and screen shake toggles of SettingsRows, and Back to the main page.
## The panel takes a share of the safe area width and stays centered in it.

signal resume_requested
signal restart_requested
signal menu_requested
## The Settings or Back button switched the page, for the click sound.
signal page_button_pressed

const PANEL_WIDTH_RATIO: float = 0.85
const RESUME_BUTTON_HEIGHT: float = 180.0
const BUTTON_HEIGHT: float = 160.0
const MAIN_PAGE_TITLE: String = "UI_PAUSE_TITLE"
const SETTINGS_PAGE_TITLE: String = "UI_SETTINGS"

@onready var _center: CenterContainer = %Center
@onready var _panel: PanelContainer = %Panel
@onready var _title_label: Label = %TitleLabel
@onready var _main_page: Control = %MainPage
@onready var _settings_page: Control = %SettingsPage
@onready var _resume_button: IconActionButton = %ResumeButton
@onready var _menu_button: IconActionButton = %MenuButton
@onready var _restart_button: IconActionButton = %RestartButton
@onready var _settings_button: IconActionButton = %SettingsButton
@onready var _back_button: IconActionButton = %BackButton


func _ready() -> void:
	_resume_button.custom_minimum_size.y = RESUME_BUTTON_HEIGHT
	for button: IconActionButton in [_menu_button, _restart_button, _settings_button, _back_button]:
		button.custom_minimum_size.y = BUTTON_HEIGHT
	_center.resized.connect(_fit_panel_width)
	_fit_panel_width()
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
	_title_label.text = MAIN_PAGE_TITLE


func show_settings_page() -> void:
	_main_page.visible = false
	_settings_page.visible = true
	_title_label.text = SETTINGS_PAGE_TITLE


func is_showing_settings() -> bool:
	return _settings_page.visible


func _fit_panel_width() -> void:
	_panel.custom_minimum_size.x = floorf(_center.size.x * PANEL_WIDTH_RATIO)
