class_name SafeAreaMargin
extends MarginContainer

## The margins set in the scene are measured from the safe area, so content never sits under a notch or a system bar.

const MARGIN_SIDES: Array[StringName] = [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]

var _base_margins: Array[int] = []


func _ready() -> void:
	for side: StringName in MARGIN_SIDES:
		_base_margins.append(get_theme_constant(side))
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()


## Converts the safe area from window pixels to viewport units.
static func compute_safe_rect(safe_area: Rect2i, window_size: Vector2i, viewport_size: Vector2) -> Rect2:
	var scale: Vector2 = viewport_size / Vector2(window_size)
	return Rect2(Vector2(safe_area.position) * scale, Vector2(safe_area.size) * scale)


static func compute_insets(safe_rect: Rect2, viewport_size: Vector2) -> Array[int]:
	return [
		ceili(safe_rect.position.x),
		ceili(safe_rect.position.y),
		ceili(viewport_size.x - safe_rect.end.x),
		ceili(viewport_size.y - safe_rect.end.y),
	]


func _apply_safe_area() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var insets: Array[int] = [0, 0, 0, 0]
	# On desktop the safe area is the usable desktop, unrelated to the game window.
	if OS.has_feature("mobile"):
		var safe_rect: Rect2 = compute_safe_rect(DisplayServer.get_display_safe_area(), DisplayServer.window_get_size(), viewport_size)
		insets = compute_insets(safe_rect, viewport_size)
	for side_index: int in MARGIN_SIDES.size():
		add_theme_constant_override(MARGIN_SIDES[side_index], _base_margins[side_index] + insets[side_index])
