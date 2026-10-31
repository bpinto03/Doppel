class_name ModalCard
extends PanelContainer

## Panel of an overlay (pause, game over): a share of its parent's width, so it follows the safe area.
## Wider content still widens it; the layout tests check that it does not.

const WIDTH_RATIO: float = 0.85


func _ready() -> void:
	get_parent_control().resized.connect(_fit_width)
	_fit_width()


func _fit_width() -> void:
	custom_minimum_size.x = floorf(get_parent_control().size.x * WIDTH_RATIO)
