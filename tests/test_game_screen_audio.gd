extends GutTest

const GAME_SCREEN_SCENE: PackedScene = preload("res://scenes/game/game_screen.tscn")
const AUDIO_CONFIG: AudioConfig = preload("res://data/audio_config.tres")
const HAPTICS_CONFIG: HapticsConfig = preload("res://data/haptics_config.tres")
const TEST_SAVE_PATH: String = "user://test_game_screen_audio_save.cfg"
const MAX_WAIT_SECONDS: float = 5.0
const SEED: int = 1234

var _save := SaveFixture.new(TEST_SAVE_PATH)
var _screen: Control
var _board_view: BoardView


func before_each() -> void:
	_save.use_test_save()
	Settings.is_music_enabled = false
	_screen = GAME_SCREEN_SCENE.instantiate()
	add_child_autofree(_screen)
	_board_view = _screen.get_node("%BoardView")
	watch_signals(AudioManager)


func after_each() -> void:
	AudioManager.stop_music()
	_save.restore_player_save()
	AudioManager.apply_settings()


func test_new_turn_plays_its_placement_sound_after_a_skip() -> void:
	_screen.start_game(_create_session(BoardState.new(3, 6)), RecordBook.get_best_score())
	_board_view.column_released.emit(0)
	_board_view.pressed_while_locked.emit()
	var placements_before: int = _count_played(AUDIO_CONFIG.placement)

	_board_view.column_released.emit(1)
	await wait_for_signal(_screen.turn_playback_finished, MAX_WAIT_SECONDS)

	assert_eq(_count_played(AUDIO_CONFIG.placement), placements_before + 1)


## Filling the last free pair ends the game, even when the turn is skipped.
func test_game_over_plays_when_the_game_ends_during_a_skipped_turn() -> void:
	_screen.start_game(_create_session(_create_board_one_pair_from_full()), RecordBook.get_best_score())

	_board_view.column_released.emit(0)
	_board_view.pressed_while_locked.emit()

	assert_eq(_count_played(AUDIO_CONFIG.game_over), 1)


func test_game_over_vibrates() -> void:
	_screen.start_game(_create_session(_create_board_one_pair_from_full()), RecordBook.get_best_score())
	watch_signals(HapticsManager)

	_board_view.column_released.emit(0)
	_board_view.pressed_while_locked.emit()
	await wait_for_signal(HapticsManager.pulse_sent, MAX_WAIT_SECONDS)

	assert_signal_emitted_with_parameters(HapticsManager, "pulse_sent", [HAPTICS_CONFIG.game_over])


func test_vibration_debug_button_switches_the_setting() -> void:
	var button: Button = _screen.get_node("%VibrationDebugButton")

	button.pressed.emit()

	assert_false(Settings.is_vibration_enabled)
	assert_eq(button.text, "DEBUG_VIBRATION_OFF")


func test_music_debug_button_switches_the_setting() -> void:
	var button: Button = _screen.get_node("%MusicDebugButton")
	# Unrequested first, so switching the setting on plays nothing in the test.
	AudioManager.stop_music()

	button.pressed.emit()

	assert_true(Settings.is_music_enabled)
	assert_eq(button.text, "DEBUG_MUSIC_ON")
	assert_false(AudioManager.is_music_loaded())


func _create_session(board: BoardState) -> GameSession:
	return GameSession.new(BalancingFixture.create_config_always_drawing(1), BalancingFixture.create_seeded_rng(SEED), board)


func _create_board_one_pair_from_full() -> BoardState:
	return BoardFixture.create_board([
		". 2 3 | 2 3 .",
		"2 3 2 | 3 2 3",
		"3 2 3 | 2 3 2",
		"2 3 2 | 3 2 3",
		"3 2 3 | 2 3 2",
		"2 3 2 | 3 2 3",
	])


func _count_played(effect: SoundEffect) -> int:
	var count: int = 0
	for index: int in get_signal_emit_count(AudioManager, "effect_played"):
		if get_signal_parameters(AudioManager, "effect_played", index)[0] == effect:
			count += 1
	return count
