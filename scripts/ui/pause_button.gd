class_name PauseButton
extends Button

## A square button whose pause symbol, two rounded bars in the font color, is drawn rather than written.

const BUTTON_SIZE := Vector2(136.0, 136.0)
## Bar sizes are relative to the button size.
const BAR_WIDTH_RATIO: float = 0.095
const BAR_HEIGHT_RATIO: float = 0.34
const BAR_GAP_RATIO: float = 0.06
## Corner radius relative to the bar width.
const BAR_CORNER_RATIO: float = 0.3

var _bar_box := StyleBoxFlat.new()


func _ready() -> void:
	custom_minimum_size = BUTTON_SIZE


func _draw() -> void:
	var bar_size := Vector2(size.x * BAR_WIDTH_RATIO, size.y * BAR_HEIGHT_RATIO)
	var gap: float = size.x * BAR_GAP_RATIO
	var first_bar_position := Vector2((size.x - bar_size.x * 2.0 - gap) / 2.0, (size.y - bar_size.y) / 2.0)
	_bar_box.bg_color = get_theme_color(&"font_color")
	_bar_box.set_corner_radius_all(roundi(bar_size.x * BAR_CORNER_RATIO))
	_bar_box.draw(get_canvas_item(), Rect2(first_bar_position, bar_size))
	_bar_box.draw(get_canvas_item(), Rect2(first_bar_position + Vector2(bar_size.x + gap, 0.0), bar_size))
