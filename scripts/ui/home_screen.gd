class_name HomeScreen
extends PaletteScreen

## Entry screen: logo and title, then Play, and Continue when a game in progress is saved; below them, Tutorial and Settings.
## The daily challenge (3.3) and the shop (3.2) will join the secondary buttons.

signal play_requested
signal continue_requested
signal tutorial_requested
signal settings_requested

const AUDIO_CONFIG: AudioConfig = preload("res://data/audio_config.tres")
const LOGO_SIZE := Vector2(480.0, 364.0)
const PRIMARY_BUTTON_HEIGHT: float = 196.0
const SECONDARY_BUTTON_HEIGHT: float = 171.0

var _choices: Array[HomeMenu.Choice] = [HomeMenu.Choice.PLAY]

@onready var _layout: VBoxContainer = %Layout
@onready var _logo: LogoMark = %Logo
@onready var _choice_buttons: BoxContainer = %ChoiceButtons
@onready var _play_button: IconActionButton = %PlayButton
@onready var _continue_button: IconActionButton = %ContinueButton
@onready var _secondary_buttons: BoxContainer = %SecondaryButtons
@onready var _tutorial_button: IconActionButton = %TutorialButton
@onready var _settings_button: IconActionButton = %SettingsButton


func _ready() -> void:
	super()
	_apply_layout_sizes()
	for button: IconActionButton in [_play_button, _continue_button, _tutorial_button, _settings_button]:
		button.pressed.connect(_play_click)
	_play_button.pressed.connect(play_requested.emit)
	_continue_button.pressed.connect(continue_requested.emit)
	_tutorial_button.pressed.connect(tutorial_requested.emit)
	_settings_button.pressed.connect(settings_requested.emit)
	_layout.resized.connect(_arrange_buttons)
	show_choices(_choices)


func show_choices(choices: Array[HomeMenu.Choice]) -> void:
	_choices = choices
	_continue_button.visible = choices.has(HomeMenu.Choice.CONTINUE)
	_arrange_buttons()


func is_choice_shown(choice: HomeMenu.Choice) -> bool:
	return _get_choice_button(choice).visible


func is_stacked() -> bool:
	return _choice_buttons.vertical


## A new language changes the button widths once the texts are updated, hence the deferred call.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_arrange_buttons.call_deferred()


func _apply_layout_sizes() -> void:
	_logo.custom_minimum_size = LOGO_SIZE
	for button: IconActionButton in [_play_button, _continue_button]:
		button.custom_minimum_size.y = PRIMARY_BUTTON_HEIGHT
	for button: IconActionButton in [_tutorial_button, _settings_button]:
		button.custom_minimum_size.y = SECONDARY_BUTTON_HEIGHT


func _play_click() -> void:
	AudioManager.play_effect(AUDIO_CONFIG.ui_click)


func _arrange_buttons() -> void:
	var choice_buttons: Array[Button] = []
	for choice: HomeMenu.Choice in _choices:
		choice_buttons.append(_get_choice_button(choice))
	_choice_buttons.vertical = _should_stack(choice_buttons, _choice_buttons)
	_secondary_buttons.vertical = _should_stack([_tutorial_button, _settings_button], _secondary_buttons)
	var ordered_choices: Array[HomeMenu.Choice] = HomeMenu.order_choices(_choices, _choice_buttons.vertical)
	for index: int in ordered_choices.size():
		_choice_buttons.move_child(_get_choice_button(ordered_choices[index]), index)


func _should_stack(buttons: Array[Button], row: BoxContainer) -> bool:
	var min_widths: Array[float] = []
	for button: Button in buttons:
		min_widths.append(button.get_combined_minimum_size().x)
	return HomeMenu.should_stack(min_widths, row.get_theme_constant(&"separation"), _layout.size.x)


func _get_choice_button(choice: HomeMenu.Choice) -> Button:
	return _continue_button if choice == HomeMenu.Choice.CONTINUE else _play_button
