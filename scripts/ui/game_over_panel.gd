class_name GameOverPanel
extends Control

## Covers the finished game: score, record, highest tile, Play again and Menu.
## RewardSlot waits for the coins earned (step 3.2) and the rewarded ad (phase 4).

signal replay_requested
signal menu_requested

@onready var _score_label: Label = %ScoreLabel
@onready var _new_record_label: Label = %NewRecordLabel
@onready var _best_label: Label = %BestLabel
@onready var _max_tile_label: Label = %MaxTileLabel
@onready var _replay_button: Button = %ReplayButton
@onready var _menu_button: Button = %MenuButton


func _ready() -> void:
	_replay_button.pressed.connect(replay_requested.emit)
	_menu_button.pressed.connect(menu_requested.emit)


func show_summary(summary: GameOverSummary) -> void:
	_score_label.text = tr("UI_SCORE").format({"value": summary.score})
	_new_record_label.visible = summary.is_new_record
	_best_label.text = tr("UI_BEST").format({"value": summary.best_score})
	_max_tile_label.text = tr("UI_MAX_TILE").format({"value": MergeScoring.calculate_tile_value(summary.highest_level)})
	visible = true


func is_new_record_shown() -> bool:
	return _new_record_label.visible
