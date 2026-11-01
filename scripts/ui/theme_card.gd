class_name ThemeCard
extends PanelContainer

## One theme of the shop: its preview, then its name, a two-line description and one action:
## Equipped (disabled, accent border and check badge), Equip, or the price beside Buy.
## The action row keeps one height, so every state gives the same card height.

signal action_pressed

enum State { EQUIPPED, OWNED, FOR_SALE }

const ACTION_TEXTS: Dictionary[State, String] = {
	State.EQUIPPED: "UI_THEME_EQUIPPED",
	State.OWNED: "UI_THEME_EQUIP",
	State.FOR_SALE: "UI_THEME_BUY",
}

## Set before the card enters the tree.
var entry: ThemeEntry
var _state: State

@onready var _preview: ThemePreview = %Preview
@onready var _name_row: Control = %NameRow
@onready var _name_label: Label = %NameLabel
@onready var _check_badge: Control = %CheckBadge
@onready var _check_icon: TextureRect = %CheckIcon
@onready var _description_label: Label = %DescriptionLabel
@onready var _actions: Control = %Actions
@onready var _price: Control = %Price
@onready var _price_icon: TextureRect = %PriceIcon
@onready var _price_label: Label = %PriceLabel
@onready var _action_button: Button = %ActionButton


func _ready() -> void:
	_apply_layout_sizes()
	_preview.palette = entry.palette
	_name_label.text = entry.display_name_key
	_description_label.text = entry.description_key
	_price_label.text = str(entry.price)
	_action_button.pressed.connect(action_pressed.emit)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_theme_items()


static func resolve_state(is_equipped: bool, is_owned: bool) -> State:
	if is_equipped:
		return State.EQUIPPED
	return State.OWNED if is_owned else State.FOR_SALE


## A theme for sale keeps its price in sight when the balance is too low; only Buy is disabled.
func show_state(state: State, can_afford: bool) -> void:
	_state = state
	var is_equipped: bool = state == State.EQUIPPED
	theme_type_variation = UiThemeBuilder.SHOP_CARD_EQUIPPED_TYPE if is_equipped else UiThemeBuilder.SHOP_CARD_TYPE
	_check_badge.visible = is_equipped
	_price.visible = state == State.FOR_SALE
	_action_button.theme_type_variation = UiThemeBuilder.SHOP_BUY_BUTTON_TYPE if state == State.FOR_SALE else UiThemeBuilder.SHOP_EQUIP_BUTTON_TYPE
	_action_button.text = ACTION_TEXTS[state]
	_action_button.disabled = is_equipped or (state == State.FOR_SALE and not can_afford)


func get_state() -> State:
	return _state


func get_action_text() -> String:
	return _action_button.text


func get_action_variation() -> StringName:
	return _action_button.theme_type_variation


func is_action_enabled() -> bool:
	return not _action_button.disabled


func is_price_shown() -> bool:
	return _price.visible


func is_check_badge_shown() -> bool:
	return _check_badge.visible


func get_description_line_count() -> int:
	return _description_label.get_visible_line_count()


func _apply_layout_sizes() -> void:
	_preview.custom_minimum_size = Vector2.ONE * UiThemeBuilder.SHOP_PREVIEW_SIZE
	_name_row.custom_minimum_size.y = UiThemeBuilder.SHOP_CHECK_BADGE_SIZE
	_check_badge.custom_minimum_size = Vector2.ONE * UiThemeBuilder.SHOP_CHECK_BADGE_SIZE
	_check_icon.custom_minimum_size = Vector2.ONE * UiThemeBuilder.SHOP_CHECK_ICON_SIZE
	_price_icon.custom_minimum_size = Vector2.ONE * UiThemeBuilder.SHOP_PRICE_ICON_SIZE
	_actions.custom_minimum_size.y = UiThemeBuilder.SHOP_BUTTON_HEIGHT
	_action_button.size_flags_stretch_ratio = UiThemeBuilder.SHOP_BUY_BUTTON_WIDTH_RATIO
	_price.size_flags_stretch_ratio = 1.0 - UiThemeBuilder.SHOP_BUY_BUTTON_WIDTH_RATIO
	_description_label.max_lines_visible = UiThemeBuilder.SHOP_DESCRIPTION_MAX_LINES
	_apply_theme_items()


## The description stays two lines high, so a one-line description keeps the card height.
func _apply_theme_items() -> void:
	_description_label.custom_minimum_size.y = _description_label.get_line_height() * UiThemeBuilder.SHOP_DESCRIPTION_MAX_LINES
	_check_icon.self_modulate = get_theme_color(&"icon_color", UiThemeBuilder.SHOP_CHECK_BADGE_TYPE)
