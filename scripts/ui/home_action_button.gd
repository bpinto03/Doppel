class_name HomeActionButton
extends Button

## A home menu button: a round badge holding an icon, the text, then a chevron.
## The badge and the chevron sit in the style's content margins, so the minimum width counts them.
## Theme items of its variation: the `badge` style box and the `badge_icon_color` color.

const BADGE_MARGIN: float = 30.0
const BADGE_SIZE: float = 92.0
const ICON_SIZE_RATIO: float = 0.5
const BADGE_TEXT_GAP: float = 26.0
const TEXT_CHEVRON_GAP: float = 12.0
const CHEVRON_SIZE := Vector2(40.0, 40.0)
const CHEVRON_MARGIN: float = 22.0
const CHEVRON_OPACITY: float = 0.6
const CHEVRON_TEXTURE: Texture2D = preload("res://assets/icons/icon_chevron_right.svg")
const TEXT_LEFT_MARGIN: float = BADGE_MARGIN + BADGE_SIZE + BADGE_TEXT_GAP
const TEXT_RIGHT_MARGIN: float = TEXT_CHEVRON_GAP + CHEVRON_SIZE.x + CHEVRON_MARGIN

@export var badge_icon: Texture2D


func _draw() -> void:
	var badge_rect := Rect2(Vector2(BADGE_MARGIN, (size.y - BADGE_SIZE) / 2.0), Vector2(BADGE_SIZE, BADGE_SIZE))
	get_theme_stylebox(&"badge").draw(get_canvas_item(), badge_rect)
	var icon_inset: float = BADGE_SIZE * (1.0 - ICON_SIZE_RATIO) / 2.0
	draw_texture_rect(badge_icon, badge_rect.grow(-icon_inset), false, get_theme_color(&"badge_icon_color"))
	var chevron_position := Vector2(size.x - CHEVRON_MARGIN - CHEVRON_SIZE.x, (size.y - CHEVRON_SIZE.y) / 2.0)
	draw_texture_rect(CHEVRON_TEXTURE, Rect2(chevron_position, CHEVRON_SIZE), false, Color(get_theme_color(&"font_color"), CHEVRON_OPACITY))
