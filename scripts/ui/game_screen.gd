class_name GameScreen
extends PaletteScreen

## One game, or the tutorial opened from the home screen. Main starts it with start_new_game(), start_tutorial() or start_game().

signal turn_playback_finished
signal home_requested

const BALANCING_CONFIG: BalancingConfig = preload("res://data/balancing.tres")
const PLAYBACK_CONFIG: ResolutionPlaybackConfig = preload("res://data/resolution_playback.tres")
const AUDIO_CONFIG: AudioConfig = preload("res://data/audio_config.tres")
const HAPTICS_CONFIG: HapticsConfig = preload("res://data/haptics_config.tres")
const TUTORIAL_HINT_CONFIG: TutorialHintConfig = preload("res://data/tutorial_hint.tres")
const TILE_TEXT_CONFIG: TileTextConfig = preload("res://data/tile_text.tres")
const NO_TUTORIAL_STEP: int = -1
const HUD_ICON_SIZE := Vector2(80.0, 80.0)
## The three preview columns share one width, so the mirror preview sits on the axis.
const PREVIEW_COLUMN_WIDTH: float = 228.0
const PREVIEW_TILE_SIZE := Vector2(176.0, 176.0)
const NEXT_PREVIEW_TILE_SIZE := Vector2(140.0, 140.0)

var _session: GameSession
var _playback: ResolutionPlayback
var _feedback: GameFeedback
var _tutorial_steps: Array[TutorialStep] = []
var _tutorial_step_index: int = NO_TUTORIAL_STEP
var _best_score_before_game: int
var _coin_reward: CoinRewardResult

@onready var _board_view: BoardView = %BoardView
@onready var _score_label: Label = %ScoreLabel
@onready var _best_label: Label = %BestLabel
@onready var _current_swatch: TileSwatch = %CurrentSwatch
@onready var _reflection_swatch: TileSwatch = %ReflectionSwatch
@onready var _next_swatch: TileSwatch = %NextSwatch
@onready var _pause_button: PauseButton = %PauseButton
@onready var _combo_label: Label = %ComboLabel
@onready var _tutorial_panel: TutorialPanel = %TutorialPanel
@onready var _game_over_panel: GameOverPanel = %GameOverPanel
@onready var _pause_panel: PausePanel = %PausePanel


func _ready() -> void:
	super()
	_apply_layout_sizes()
	_playback = ResolutionPlayback.new(PLAYBACK_CONFIG, _board_view, _combo_label)
	_playback.playback_finished.connect(_on_playback_finished)
	_feedback = GameFeedback.new(AUDIO_CONFIG, HAPTICS_CONFIG, _playback, _board_view)
	_board_view.pressed_while_locked.connect(_playback.skip)
	_board_view.column_released.connect(_on_column_released)
	_tutorial_panel.next_requested.connect(_on_tutorial_next_requested)
	_tutorial_panel.skip_requested.connect(home_requested.emit)
	_tutorial_panel.next_requested.connect(_feedback.play_ui_click)
	_tutorial_panel.skip_requested.connect(_feedback.play_ui_click)
	_game_over_panel.replay_requested.connect(start_new_game)
	_game_over_panel.menu_requested.connect(home_requested.emit)
	_game_over_panel.replay_requested.connect(_feedback.play_ui_click)
	_game_over_panel.menu_requested.connect(_feedback.play_ui_click)
	_pause_button.pressed.connect(open_pause)
	_pause_panel.resume_requested.connect(close_pause)
	_pause_panel.restart_requested.connect(start_new_game)
	_pause_panel.menu_requested.connect(home_requested.emit)
	for button_signal: Signal in [_pause_button.pressed, _pause_panel.resume_requested, _pause_panel.restart_requested, _pause_panel.menu_requested, _pause_panel.page_button_pressed]:
		button_signal.connect(_feedback.play_ui_click)
	AppLifecycle.deactivated.connect(_on_app_deactivated)


func _apply_layout_sizes() -> void:
	for icon: TextureRect in [%ScoreIcon, %RecordIcon]:
		icon.custom_minimum_size = HUD_ICON_SIZE
	for swatch: TileSwatch in [_current_swatch, _reflection_swatch, _next_swatch]:
		(swatch.get_parent() as Control).custom_minimum_size.x = PREVIEW_COLUMN_WIDTH
	_current_swatch.custom_minimum_size = PREVIEW_TILE_SIZE
	_reflection_swatch.custom_minimum_size = PREVIEW_TILE_SIZE
	_next_swatch.custom_minimum_size = NEXT_PREVIEW_TILE_SIZE


## Replaces the saved game in progress, after counting it for the record.
func start_new_game() -> void:
	var abandoned_session: GameSession = CurrentGameStore.load_session(BALANCING_CONFIG)
	if abandoned_session != null:
		RecordBook.submit(abandoned_session)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	start_game(GameSession.new(BALANCING_CONFIG, rng), RecordBook.get_best_score())
	CurrentGameStore.store(_session, _best_score_before_game)


## Plays the given game outside the tutorial, as it is: a resumed game shows its board without animation.
## best_score_before_game tells the game over screen whether this game beat the record.
func start_game(session: GameSession, best_score_before_game: int) -> void:
	_stop_tutorial()
	_game_over_panel.visible = false
	_pause_panel.visible = false
	_pause_button.visible = true
	_session = session
	_best_score_before_game = best_score_before_game
	_coin_reward = null
	_set_input_enabled(true)
	_refresh()


## The saved game stays untouched: the tutorial ends on the home screen, on its last step or on Skip.
func start_tutorial() -> void:
	_tutorial_steps = TutorialScenarios.create_steps()
	_tutorial_panel.fit_to_steps(_tutorial_steps)
	_show_tutorial_step(0)


func get_session() -> GameSession:
	return _session


## Null until a real game ends in game over.
func get_coin_reward() -> CoinRewardResult:
	return _coin_reward


func is_tutorial_running() -> bool:
	return _tutorial_step_index != NO_TUTORIAL_STEP


func get_navigation_state() -> ScreenNavigation.GameState:
	if is_tutorial_running():
		return ScreenNavigation.GameState.TUTORIAL
	if _game_over_panel.visible:
		return ScreenNavigation.GameState.GAME_OVER
	if _pause_panel.visible:
		return ScreenNavigation.GameState.PAUSE_SETTINGS if _pause_panel.is_showing_settings() else ScreenNavigation.GameState.PAUSED
	return ScreenNavigation.GameState.PLAYING


## The playback jumps to its final state first; if that turn ended the game, the game over screen shows instead.
func open_pause() -> void:
	_board_view.cancel_press()
	_playback.skip()
	if get_navigation_state() != ScreenNavigation.GameState.PLAYING:
		return
	_pause_panel.show_main_page()
	_pause_panel.visible = true
	_set_input_enabled(false)


## Back to the main page of the pause; the game stays paused.
func close_pause_settings() -> void:
	_pause_panel.show_main_page()


func close_pause() -> void:
	_pause_panel.visible = false
	_set_input_enabled(true)


func get_tutorial_step_index() -> int:
	return _tutorial_step_index


func _show_tutorial_step(step_index: int) -> void:
	_tutorial_step_index = step_index
	_pause_button.visible = false
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
		home_requested.emit()


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


## The turn is already saved: the display jumps to the final state, so the app never resumes half animated.
## A real game also pauses, so the player resumes it on purpose.
func _on_app_deactivated() -> void:
	if ScreenNavigation.should_pause_when_inactive(get_navigation_state()):
		open_pause()
	else:
		_board_view.cancel_press()
		_playback.skip()


## Saved before the playback: the session already holds the final state of the turn, and the app may be killed mid-animation.
## On game over, the coins and the erased game are changed in the same frame, so they reach the disk in one write
## (see docs/decisions/0007-coins-and-wallet.md).
func _save_turn() -> void:
	RecordBook.submit(_session)
	if _session.is_game_over:
		_pay_coin_reward()
		CurrentGameStore.erase()
	else:
		CurrentGameStore.store(_session, _best_score_before_game)


func _pay_coin_reward() -> void:
	var coins_earned: int = CoinReward.calculate_coins(_session.score, _session.highest_level_reached, BALANCING_CONFIG)
	if coins_earned > 0:
		CoinWallet.add_coins(coins_earned)
	_coin_reward = CoinRewardResult.new(coins_earned, CoinWallet.get_coins())


## In the tutorial, the board stays locked until the player moves to the next step.
func _on_playback_finished() -> void:
	_refresh()
	if _session.is_game_over:
		_feedback.play_game_over()
		_game_over_panel.show_summary(GameOverSummary.new(_session, _best_score_before_game, RecordBook.get_best_score()), _coin_reward)
	if is_tutorial_running():
		_tutorial_panel.show_explanation(_tutorial_steps[_tutorial_step_index].explanation_key, _is_last_tutorial_step())
	else:
		_set_input_enabled(true)
	turn_playback_finished.emit()


func _is_last_tutorial_step() -> bool:
	return _tutorial_step_index == _tutorial_steps.size() - 1


func _set_input_enabled(is_enabled: bool) -> void:
	_board_view.is_input_enabled = is_enabled


func _refresh() -> void:
	_board_view.show_session(_session)
	_score_label.text = str(_session.score)
	_best_label.text = str(RecordBook.get_best_score())
	_current_swatch.level = _session.tile_generator.current_level
	_reflection_swatch.level = _session.get_next_reflection_level()
	_next_swatch.level = _session.tile_generator.next_level


func _apply_screen_palette(palette: ThemePalette) -> void:
	(%ScoreIcon as TextureRect).texture = palette.score_icon
	(%RecordIcon as TextureRect).texture = palette.record_icon
	_game_over_panel.apply_palette(palette)
	_tutorial_panel.apply_palette(palette)
	_combo_label.add_theme_color_override(&"font_outline_color", palette.background)
	var tile_painter := TilePainter.new(palette, TILE_TEXT_CONFIG)
	_board_view.tile_painter = tile_painter
	for swatch: TileSwatch in [_current_swatch, _reflection_swatch, _next_swatch]:
		swatch.tile_painter = tile_painter
