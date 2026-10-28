extends GutTest

const SEED: int = 1234
const BOARD_VIEW_SIZE := Vector2(700.0, 600.0)
const SHORT_DURATION: float = 0.01
const MAX_WAIT_SECONDS: float = 5.0
const SETTLE_SECONDS: float = 0.2

var _board_view: BoardView
var _combo_label: Label


func before_each() -> void:
	_board_view = BoardView.new()
	_board_view.size = BOARD_VIEW_SIZE
	_board_view.tile_painter = TilePainter.new(preload("res://data/palette_paper.tres"), preload("res://data/tile_text.tres"))
	add_child_autofree(_board_view)
	_combo_label = Label.new()
	_combo_label.visible = false
	add_child_autofree(_combo_label)


func test_skipping_several_times_finishes_once_on_the_session_board() -> void:
	var session: GameSession = _create_chain_session()
	var playback: ResolutionPlayback = _create_playback()
	watch_signals(playback)

	_play_turn(session, playback)
	playback.skip()
	playback.skip()
	await wait_seconds(SETTLE_SECONDS)

	assert_signal_emit_count(playback, "playback_finished", 1)
	assert_false(playback.is_playing)
	assert_false(_combo_label.visible)
	assert_eq(BoardFixture.describe_board(_board_view.get_displayed_board()), BoardFixture.describe_board(session.board))


func test_playback_left_to_run_finishes_once_on_the_session_board() -> void:
	var session: GameSession = _create_chain_session()
	var playback: ResolutionPlayback = _create_playback()
	watch_signals(playback)

	_play_turn(session, playback)
	await wait_for_signal(playback.playback_finished, MAX_WAIT_SECONDS)
	playback.skip()

	assert_signal_emit_count(playback, "playback_finished", 1)
	assert_eq(BoardFixture.describe_board(_board_view.get_displayed_board()), BoardFixture.describe_board(session.board))


func test_board_shake_is_cleared_when_the_turn_ends() -> void:
	var session: GameSession = _create_chain_session()
	var playback: ResolutionPlayback = _create_playback()

	_play_turn(session, playback)
	await wait_for_signal(playback.playback_finished, MAX_WAIT_SECONDS)

	assert_eq(_board_view.get_shake_offset(), Vector2.ZERO)


func test_board_shake_is_cleared_when_the_turn_is_skipped() -> void:
	var session: GameSession = _create_chain_session()
	var playback: ResolutionPlayback = _create_playback()

	_play_turn(session, playback)
	await wait_seconds(SETTLE_SECONDS)
	playback.skip()

	assert_eq(_board_view.get_shake_offset(), Vector2.ZERO)


func test_skip_during_a_combo_hides_it_at_once() -> void:
	var session: GameSession = _create_chain_session()
	var config: ResolutionPlaybackConfig = _create_config()
	config.step_pause = SETTLE_SECONDS
	var playback: ResolutionPlayback = _create_playback(config)

	_play_turn(session, playback)
	await wait_until(func() -> bool: return _combo_label.visible, MAX_WAIT_SECONDS)
	assert_true(_combo_label.visible)
	playback.skip()

	assert_false(_combo_label.visible)


func test_combo_stays_a_moment_after_a_turn_played_to_the_end() -> void:
	var session: GameSession = _create_chain_session()
	var config: ResolutionPlaybackConfig = _create_config()
	config.combo_hold_duration = SETTLE_SECONDS
	var playback: ResolutionPlayback = _create_playback(config)

	_play_turn(session, playback)
	await wait_for_signal(playback.playback_finished, MAX_WAIT_SECONDS)
	assert_true(_combo_label.visible)
	await wait_seconds(SETTLE_SECONDS * 2.0)

	assert_false(_combo_label.visible)


func test_displayed_board_starts_from_the_board_before_the_turn() -> void:
	var session: GameSession = _create_chain_session()
	var board_before: Array[String] = BoardFixture.describe_board(session.board)
	var playback: ResolutionPlayback = _create_playback()

	_play_turn(session, playback)

	assert_true(playback.is_playing)
	assert_eq(BoardFixture.describe_board(_board_view.get_displayed_board()), board_before)
	playback.skip()


func _play_turn(session: GameSession, playback: ResolutionPlayback) -> void:
	var board_before: BoardState = session.board.duplicate_board()
	var chain_result: ChainResult = session.play_column(0)
	playback.play(board_before, chain_result.events)


func _create_playback(config: ResolutionPlaybackConfig = _create_config()) -> ResolutionPlayback:
	return ResolutionPlayback.new(config, _board_view, _combo_label)


func _create_config() -> ResolutionPlaybackConfig:
	var config := ResolutionPlaybackConfig.new()
	config.drop_duration = SHORT_DURATION
	config.fall_duration = SHORT_DURATION
	config.landing_squash_duration = SHORT_DURATION
	config.merge_pulse_duration = SHORT_DURATION
	config.merge_converge_duration = SHORT_DURATION
	config.merge_pop_duration = SHORT_DURATION
	config.merge_pop_scale = 1.0
	config.merge_pop_max_scale = 1.0
	config.chain_intensity_curve = Curve.new()
	config.chain_intensity_max_link = 2
	config.chain_max_speed_up = 1.0
	config.particles_per_merge = 1
	config.max_particles_per_burst = 1
	config.max_live_particles = 1
	config.particle_lifetime = SHORT_DURATION
	config.shake_min_link = 1
	config.shake_amplitude = 0.1
	config.shake_max_amplitude = 0.1
	config.shake_duration = MAX_WAIT_SECONDS
	config.combo_pop_scale = 1.0
	config.combo_pop_duration = SHORT_DURATION
	config.combo_hold_duration = SHORT_DURATION
	config.step_pause = SHORT_DURATION
	config.max_chain_duration = MAX_WAIT_SECONDS
	return config


## Playing column 0 with a 1 triggers a three-link chain.
func _create_chain_session() -> GameSession:
	var board: BoardState = BoardFixture.create_board([
		". . . | . . .",
		". . . | . . .",
		". . . | . . .",
		". . . | . . .",
		". 3 . | . . .",
		"1 2 . | . . .",
	])
	return GameSession.new(BalancingFixture.create_config_always_drawing(1), BalancingFixture.create_seeded_rng(SEED), board)
