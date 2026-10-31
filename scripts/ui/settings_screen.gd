class_name SettingsScreen
extends PaletteScreen

## Every setting, from the home screen. The rows are SettingsRows, showing all their groups.
## Later settings (phase 4: ad consent, remove ads, restore purchase, privacy policy) join SettingsRows as a new group.

signal back_requested

@onready var _back_button: Button = %BackButton


func _ready() -> void:
	super()
	_back_button.pressed.connect(back_requested.emit)
