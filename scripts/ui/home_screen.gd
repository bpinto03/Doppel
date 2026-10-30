class_name HomeScreen
extends PaletteScreen

## Entry screen: Play, and Continue when a game in progress is saved. Step 3.1 adds its other entries to the choice buttons.

signal play_requested
signal continue_requested

var _choices: Array[HomeMenu.Choice] = [HomeMenu.Choice.PLAY]

@onready var _layout: VBoxContainer = %Layout
@onready var _choice_buttons: BoxContainer = %ChoiceButtons
@onready var _play_button: Button = %PlayButton
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	super()
	_play_button.pressed.connect(play_requested.emit)
	_continue_button.pressed.connect(continue_requested.emit)
	_layout.resized.connect(_arrange_choice_buttons)
	show_choices(_choices)


func show_choices(choices: Array[HomeMenu.Choice]) -> void:
	_choices = choices
	_continue_button.visible = choices.has(HomeMenu.Choice.CONTINUE)
	_arrange_choice_buttons()


func is_choice_shown(choice: HomeMenu.Choice) -> bool:
	return _get_choice_button(choice).visible


func is_stacked() -> bool:
	return _choice_buttons.vertical


## A new language changes the button widths once the texts are updated, hence the deferred call.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_arrange_choice_buttons.call_deferred()


func _arrange_choice_buttons() -> void:
	var min_widths: Array[float] = []
	for choice: HomeMenu.Choice in _choices:
		min_widths.append(_get_choice_button(choice).get_combined_minimum_size().x)
	var separation: float = _choice_buttons.get_theme_constant(&"separation")
	_choice_buttons.vertical = HomeMenu.should_stack(min_widths, separation, _layout.size.x)
	var ordered_choices: Array[HomeMenu.Choice] = HomeMenu.order_choices(_choices, _choice_buttons.vertical)
	for index: int in ordered_choices.size():
		_choice_buttons.move_child(_get_choice_button(ordered_choices[index]), index)


func _get_choice_button(choice: HomeMenu.Choice) -> Button:
	return _continue_button if choice == HomeMenu.Choice.CONTINUE else _play_button
