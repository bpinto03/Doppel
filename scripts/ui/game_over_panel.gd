class_name GameOverPanel
extends Control

## Covers the finished game: the crown and its halo above the panel, then score, record and highest tile rows,
## Play again and Menu. Each game over fades the panel in and throws confetti, more of them on a new record.
## RewardSlot waits for the coins earned (step 3.2) and the rewarded ad (phase 4).

signal replay_requested
signal menu_requested

const EFFECTS_CONFIG: GameOverEffectsConfig = preload("res://data/game_over_effects.tres")
const REPLAY_BUTTON_HEIGHT: float = 180.0
const MENU_BUTTON_HEIGHT: float = 160.0
const STAT_ICON_SIZE := Vector2(72.0, 72.0)
const CROWN_SIZE := Vector2(240.0, 240.0)
## Share of the crown above the top edge of the panel.
const CROWN_ABOVE_PANEL_RATIO: float = 0.35
## Halo size relative to the crown.
const HALO_SIZE_RATIO: float = 2.2

var _confetti := ConfettiBurst.new(EFFECTS_CONFIG)
var _tile_colors: Array[Color] = []
var _appear_tween: Tween
var _halo_turn_tween: Tween
var _halo_breath_tween: Tween

@onready var _content: Control = %Content
@onready var _panel: PanelContainer = %Panel
@onready var _crown_space: Control = %CrownSpace
@onready var _halo: CrownHalo = %Halo
@onready var _crown: TextureRect = %Crown
@onready var _new_record_label: Label = %NewRecordLabel
@onready var _score_icon: TextureRect = %ScoreIcon
@onready var _record_icon: TextureRect = %RecordIcon
@onready var _max_tile_icon: TextureRect = %MaxTileIcon
@onready var _score_value: Label = %ScoreValue
@onready var _best_value: Label = %BestValue
@onready var _max_tile_value: Label = %MaxTileValue
@onready var _replay_button: IconActionButton = %ReplayButton
@onready var _menu_button: IconActionButton = %MenuButton


func _ready() -> void:
	_replay_button.custom_minimum_size.y = REPLAY_BUTTON_HEIGHT
	_menu_button.custom_minimum_size.y = MENU_BUTTON_HEIGHT
	for icon: TextureRect in [_score_icon, _record_icon, _max_tile_icon]:
		icon.custom_minimum_size = STAT_ICON_SIZE
	# The crown bottom lines up with the bottom of this space, which starts after the panel padding.
	_crown_space.custom_minimum_size.y = CROWN_SIZE.y * (1.0 - CROWN_ABOVE_PANEL_RATIO) - UiThemeBuilder.MODAL_CARD_PADDING
	_crown.size = CROWN_SIZE
	_halo.size = CROWN_SIZE * HALO_SIZE_RATIO
	_halo.pivot_offset = _halo.size / 2.0
	_confetti.name = "Confetti"
	add_child(_confetti)
	_panel.item_rect_changed.connect(_follow_panel)
	_follow_panel()
	_replay_button.pressed.connect(replay_requested.emit)
	_menu_button.pressed.connect(menu_requested.emit)


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_node_ready() and not visible:
		_stop_effects()


func apply_palette(palette: ThemePalette) -> void:
	_crown.texture = palette.score_icon
	_score_icon.texture = palette.score_icon
	_record_icon.texture = palette.record_icon
	_max_tile_icon.self_modulate = palette.game_over_tile_icon
	_halo.color = palette.game_over_halo
	_tile_colors = palette.tile_colors


func show_summary(summary: GameOverSummary) -> void:
	_score_value.text = str(summary.score)
	_best_value.text = str(summary.best_score)
	_max_tile_value.text = str(MergeScoring.calculate_tile_value(summary.highest_level))
	_new_record_label.visible = summary.is_new_record
	visible = true
	_appear()
	_animate_halo()
	_burst_confetti_after_layout(summary.is_new_record)


func is_new_record_shown() -> bool:
	return _new_record_label.visible


func is_halo_animated() -> bool:
	return _halo_turn_tween != null and _halo_turn_tween.is_running()


func _appear() -> void:
	_content.pivot_offset = _content.size / 2.0
	_content.scale = Vector2.ONE * EFFECTS_CONFIG.appear_start_scale
	modulate.a = 0.0
	_appear_tween = create_tween().set_parallel()
	_appear_tween.tween_property(_content, "scale", Vector2.ONE, EFFECTS_CONFIG.appear_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_appear_tween.tween_property(self, "modulate:a", 1.0, EFFECTS_CONFIG.appear_duration)


## Loops until the panel hides; only the halo transform and opacity change, so nothing is redrawn.
func _animate_halo() -> void:
	_halo_turn_tween = create_tween().set_loops()
	_halo_turn_tween.tween_property(_halo, "rotation", TAU, EFFECTS_CONFIG.halo_turn_duration).from(0.0)
	_halo_breath_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	_halo_breath_tween.tween_property(_halo, "modulate:a", EFFECTS_CONFIG.halo_min_opacity, EFFECTS_CONFIG.halo_breath_duration)
	_halo_breath_tween.tween_property(_halo, "modulate:a", 1.0, EFFECTS_CONFIG.halo_breath_duration)


## Shown just now, the panel is laid out at the end of this frame: confetti thrown before would leave from its old place.
func _burst_confetti_after_layout(is_record: bool) -> void:
	await get_tree().process_frame
	if visible:
		_follow_panel()
		_confetti.burst(_tile_colors, is_record)


func _stop_effects() -> void:
	for tween: Tween in [_appear_tween, _halo_turn_tween, _halo_breath_tween]:
		if tween != null:
			tween.kill()
	_content.scale = Vector2.ONE
	modulate.a = 1.0
	_halo.rotation = 0.0
	_halo.modulate.a = 1.0
	_confetti.clear()


## The crown straddles the top edge of the panel, centered, with the halo behind it; confetti leave from that edge.
func _follow_panel() -> void:
	var panel_rect: Rect2 = _get_panel_rect()
	_confetti.place_line(Vector2(panel_rect.get_center().x, panel_rect.position.y), panel_rect.size.x)
	var crown_center := Vector2(panel_rect.get_center().x, panel_rect.position.y + CROWN_SIZE.y * (0.5 - CROWN_ABOVE_PANEL_RATIO))
	_crown.position = crown_center - CROWN_SIZE / 2.0
	_halo.position = crown_center - _halo.size / 2.0


## In the coordinates of the content, so the appearance scale does not move it.
func _get_panel_rect() -> Rect2:
	return Rect2(_content.get_global_transform().affine_inverse() * _panel.global_position, _panel.size)
