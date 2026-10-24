extends Control

const BALANCING_CONFIG: BalancingConfig = preload("res://data/balancing.tres")
const NO_TILE_TEXT: String = "-"

var _session: GameSession
var _best_score: int

@onready var _board_view: BoardView = %BoardView
@onready var _score_label: Label = %ScoreLabel
@onready var _best_label: Label = %BestLabel
@onready var _max_tile_label: Label = %MaxTileLabel
@onready var _current_swatch: TileSwatch = %CurrentSwatch
@onready var _reflection_swatch: TileSwatch = %ReflectionSwatch
@onready var _next_swatch: TileSwatch = %NextSwatch
@onready var _game_over_label: Label = %GameOverLabel
@onready var _restart_button: Button = %RestartButton


func _ready() -> void:
	_board_view.column_tapped.connect(_on_column_tapped)
	_restart_button.pressed.connect(start_new_game)
	start_new_game()


func start_new_game() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_session = GameSession.new(BALANCING_CONFIG, rng)
	_refresh()


func _on_column_tapped(column: int) -> void:
	if not _session.can_play_column(column):
		return
	_session.play_column(column)
	_best_score = maxi(_best_score, _session.score)
	_refresh()


func _refresh() -> void:
	_board_view.show_session(_session)
	_score_label.text = tr("UI_SCORE").format({"value": _session.score})
	_best_label.text = tr("UI_BEST").format({"value": _best_score})
	_max_tile_label.text = tr("UI_MAX_TILE").format({"value": _format_highest_tile()})
	_current_swatch.level = _session.tile_generator.current_level
	_reflection_swatch.level = _session.get_next_reflection_level()
	_next_swatch.level = _session.tile_generator.next_level
	_game_over_label.visible = _session.is_game_over


func _format_highest_tile() -> String:
	if _session.highest_level_reached == BoardState.EMPTY_CELL:
		return NO_TILE_TEXT
	return str(MergeScoring.calculate_tile_value(_session.highest_level_reached))
