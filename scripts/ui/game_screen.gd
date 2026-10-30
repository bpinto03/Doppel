class_name GameScreen
extends PaletteScreen

## One game, or the tutorial. Main starts it with start_new_game(), start_tutorial() or start_game().

signal turn_playback_finished

const BALANCING_CONFIG: BalancingConfig = preload("res://data/balancing.tres")
const PLAYBACK_CONFIG: ResolutionPlaybackConfig = preload("res://data/resolution_playback.tres")
const AUDIO_CONFIG: AudioConfig = preload("res://data/audio_config.tres")
const HAPTICS_CONFIG: HapticsConfig = preload("res://data/haptics_config.tres")
const TUTORIAL_HINT_CONFIG: TutorialHintConfig = preload("res://data/tutorial_hint.tres")
const TILE_TEXT_CONFIG: TileTextConfig = preload("res://data/tile_text.tres")
const NO_TILE_TEXT: String = "-"
const NO_TUTORIAL_STEP: int = -1

var _session: GameSession
var _playback: ResolutionPlayback
var _feedback: GameFeedback
var _tutorial_steps: Array[TutorialStep] = []
var _tutorial_step_index: int = NO_TUTORIAL_STEP

@onready var _board_view: BoardView = %BoardView
@onready var _score_label: Label = %ScoreLabel
@onready var _best_label: Label = %BestLabel
@onready var _max_tile_label: Label = %MaxTileLabel
@onready var _current_swatch: TileSwatch = %CurrentSwatch
@onready var _reflection_swatch: TileSwatch = %ReflectionSwatch
@onready var _next_swatch: TileSwatch = %NextSwatch
@onready var _game_over_label: Label = %GameOverLabel
@onready var _restart_button: Button = %RestartButton
@onready var _help_button: Button = %HelpButton
@onready var _combo_label: Label = %ComboLabel
@onready var _tutorial_panel: TutorialPanel = %TutorialPanel
@onready var _debug_tools: HBoxContainer = %DebugTools
@onready var _theme_debug_button: Button = %ThemeDebugButton
@onready var _vibration_debug_button: Button = %VibrationDebugButton
@onready var _music_debug_button: Button = %MusicDebugButton


func _ready() -> void:
	super()
	_playback = ResolutionPlayback.new(PLAYBACK_CONFIG, _board_view, _combo_label)
	_playback.playback_finished.connect(_on_playback_finished)
	_feedback = GameFeedback.new(AUDIO_CONFIG, HAPTICS_CONFIG, _playback, _board_view)
	_board_view.pressed_while_locked.connect(_playback.skip)
	_board_view.column_released.connect(_on_column_released)
	_restart_button.pressed.connect(start_new_game)
	_help_button.pressed.connect(start_tutorial)
	_tutorial_panel.next_requested.connect(_on_tutorial_next_requested)
	_tutorial_panel.skip_requested.connect(start_new_game)
	_restart_button.pressed.connect(_feedback.play_ui_click)
	_help_button.pressed.connect(_feedback.play_ui_click)
	_tutorial_panel.next_requested.connect(_feedback.play_ui_click)
	_tutorial_panel.skip_requested.connect(_feedback.play_ui_click)
	_set_up_debug_tools()


## Replaces the saved game in progress, after counting it for the record.
func start_new_game() -> void:
	var abandoned_session: GameSession = CurrentGameStore.load_session(BALANCING_CONFIG)
	if abandoned_session != null:
		RecordBook.submit(abandoned_session)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	start_game(GameSession.new(BALANCING_CONFIG, rng))
	CurrentGameStore.store(_session)


## Plays the given game outside the tutorial, as it is: a resumed game shows its board without animation.
func start_game(session: GameSession) -> void:
	_stop_tutorial()
	_session = session
	_set_input_enabled(true)
	_refresh()


## Leaves the saved game untouched: it is only replaced when a new game starts, after the tutorial.
func start_tutorial() -> void:
	_tutorial_steps = TutorialScenarios.create_steps()
	_show_tutorial_step(0)


func get_session() -> GameSession:
	return _session


func is_tutorial_running() -> bool:
	return _tutorial_step_index != NO_TUTORIAL_STEP


func get_tutorial_step_index() -> int:
	return _tutorial_step_index


func _show_tutorial_step(step_index: int) -> void:
	_tutorial_step_index = step_index
	var step: TutorialStep = _tutorial_steps[step_index]
	_session = step.create_session()
	_set_input_enabled(true)
	_refresh()
	_board_view.show_tutorial_hint(step, TUTORIAL_HINT_CONFIG.pulse_period)
	_tutorial_panel.show_instruction(step.instruction_key)


func _on_tutorial_next_requested() -> void:
	var next_step_index: int = _tutorial_step_index + 1
	if next_step_index < _tutorial_steps.size():
		_show_tutorial_step(next_step_index)
	else:
		start_new_game()


func _stop_tutorial() -> void:
	_tutorial_step_index = NO_TUTORIAL_STEP
	_board_view.clear_tutorial_hint()
	_tutorial_panel.visible = false


func _on_column_released(column: int) -> void:
	if not _session.can_play_column(column):
		return
	var board_before: BoardState = _session.board.duplicate_board()
	var chain_result: ChainResult = _session.play_column(column)
	if is_tutorial_running():
		_board_view.clear_tutorial_hint()
	else:
		_save_turn()
	_set_input_enabled(false)
	_playback.play(board_before, chain_result.events)


## Saved before the playback: the session already holds the final state of the turn, and the app may be killed mid-animation.
func _save_turn() -> void:
	RecordBook.submit(_session)
	if _session.is_game_over:
		CurrentGameStore.erase()
	else:
		CurrentGameStore.store(_session)


## In the tutorial, the board stays locked until the player moves to the next step.
func _on_playback_finished() -> void:
	_refresh()
	if _session.is_game_over:
		_feedback.play_game_over()
	if is_tutorial_running():
		_restart_button.disabled = false
		_help_button.disabled = false
		_tutorial_panel.show_explanation(_tutorial_steps[_tutorial_step_index].explanation_key, _is_last_tutorial_step())
	else:
		_set_input_enabled(true)
	turn_playback_finished.emit()


func _is_last_tutorial_step() -> bool:
	return _tutorial_step_index == _tutorial_steps.size() - 1


func _set_input_enabled(is_enabled: bool) -> void:
	_board_view.is_input_enabled = is_enabled
	_restart_button.disabled = not is_enabled
	_help_button.disabled = not is_enabled


func _refresh() -> void:
	_board_view.show_session(_session)
	_score_label.text = tr("UI_SCORE").format({"value": _session.score})
	_best_label.text = tr("UI_BEST").format({"value": RecordBook.get_best_score()})
	_max_tile_label.text = tr("UI_MAX_TILE").format({"value": _format_highest_tile()})
	_current_swatch.level = _session.tile_generator.current_level
	_reflection_swatch.level = _session.get_next_reflection_level()
	_next_swatch.level = _session.tile_generator.next_level
	_game_over_label.visible = _session.is_game_over


func _apply_screen_palette(palette: ThemePalette) -> void:
	_combo_label.add_theme_color_override(&"font_outline_color", palette.background)
	var tile_painter := TilePainter.new(palette, TILE_TEXT_CONFIG)
	_board_view.tile_painter = tile_painter
	for swatch: TileSwatch in [_current_swatch, _reflection_swatch, _next_swatch]:
		swatch.tile_painter = tile_painter


## Debug builds only, to compare themes, switch vibration and music, and measure playback frame rate and audio latency on a phone until the settings screen exists (step 3.1).
func _set_up_debug_tools() -> void:
	if not OS.is_debug_build():
		return
	print("System dark mode: %s" % DisplayServer.is_dark_mode())
	add_child(FrameRateProbe.new(_playback))
	add_child(AudioLatencyProbe.new())
	_debug_tools.visible = true
	_theme_debug_button.pressed.connect(_switch_to_next_palette)
	_vibration_debug_button.pressed.connect(_switch_vibration)
	_show_vibration_setting()
	_music_debug_button.pressed.connect(_switch_music)
	_show_music_setting()


func _switch_to_next_palette() -> void:
	var palette_names: Array[String] = []
	palette_names.assign(Settings.PALETTES.keys())
	var next_index: int = (palette_names.find(Settings.palette_name) + 1) % palette_names.size()
	Settings.palette_name = palette_names[next_index]


func _switch_vibration() -> void:
	Settings.is_vibration_enabled = not Settings.is_vibration_enabled
	_show_vibration_setting()


func _show_vibration_setting() -> void:
	_vibration_debug_button.text = "DEBUG_VIBRATION_ON" if Settings.is_vibration_enabled else "DEBUG_VIBRATION_OFF"


func _switch_music() -> void:
	Settings.is_music_enabled = not Settings.is_music_enabled
	_show_music_setting()


func _show_music_setting() -> void:
	_music_debug_button.text = "DEBUG_MUSIC_ON" if Settings.is_music_enabled else "DEBUG_MUSIC_OFF"


func _format_highest_tile() -> String:
	if _session.highest_level_reached == BoardState.EMPTY_CELL:
		return NO_TILE_TEXT
	return str(MergeScoring.calculate_tile_value(_session.highest_level_reached))
