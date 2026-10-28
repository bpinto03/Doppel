extends GutTest

const GAME_SCREEN_SCENE: PackedScene = preload("res://scenes/game/game_screen.tscn")
const AUDIO_CONFIG: AudioConfig = preload("res://data/audio_config.tres")
const MAX_WAIT_SECONDS: float = 5.0
const SEED: int = 1234

var _screen: Control
var _board_view: BoardView


func before_each() -> void:
	_screen = GAME_SCREEN_SCENE.instantiate()
	add_child_autofree(_screen)
	_board_view = _screen.get_node("%BoardView")
	watch_signals(AudioManager)


func test_new_turn_plays_its_placement_sound_after_a_skip() -> void:
	_screen.start_game(_create_session(BoardState.new(3, 6)))
	_board_view.column_released.emit(0)
	_board_view.pressed_while_locked.emit()
	var placements_before: int = _count_played(AUDIO_CONFIG.placement)

	_board_view.column_released.emit(1)
	await wait_for_signal(_screen.turn_playback_finished, MAX_WAIT_SECONDS)

	assert_eq(_count_played(AUDIO_CONFIG.placement), placements_before + 1)


## Filling the last free pair ends the game, even when the turn is skipped.
func test_game_over_plays_when_the_game_ends_during_a_skipped_turn() -> void:
	_screen.start_game(_create_session(BoardFixture.create_board([
		". 2 3 | 2 3 .",
		"2 3 2 | 3 2 3",
		"3 2 3 | 2 3 2",
		"2 3 2 | 3 2 3",
		"3 2 3 | 2 3 2",
		"2 3 2 | 3 2 3",
	])))

	_board_view.column_released.emit(0)
	_board_view.pressed_while_locked.emit()

	assert_eq(_count_played(AUDIO_CONFIG.game_over), 1)


func _create_session(board: BoardState) -> GameSession:
	return GameSession.new(BalancingFixture.create_config_always_drawing(1), BalancingFixture.create_seeded_rng(SEED), board)


func _count_played(effect: SoundEffect) -> int:
	var count: int = 0
	for index: int in get_signal_emit_count(AudioManager, "effect_played"):
		if get_signal_parameters(AudioManager, "effect_played", index)[0] == effect:
			count += 1
	return count
