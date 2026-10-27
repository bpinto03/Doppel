class_name ResolutionPlayback
extends RefCounted

## Replays a turn's resolution events on a copy of the board taken before the turn.
## The session already holds the final state: skipping only fast-forwards the display.

signal playback_finished

var is_playing: bool

var _config: ResolutionPlaybackConfig
var _board_view: BoardView
var _chain_label: Label
var _particles: MergeParticles
var _displayed_board: BoardState
var _events: Array[ResolutionEvent]
var _next_event_index: int
var _tween: Tween
var _planned_duration: float
var _shake_tween: Tween
var _shake_rng := RandomNumberGenerator.new()


func _init(config: ResolutionPlaybackConfig, board_view: BoardView, chain_label: Label) -> void:
	_config = config
	_board_view = board_view
	_chain_label = chain_label
	_particles = MergeParticles.new(config)
	board_view.add_board_effect(_particles)


func play(board_before: BoardState, events: Array[ResolutionEvent]) -> void:
	assert(not is_playing, "A playback is already running")
	is_playing = true
	_displayed_board = board_before.duplicate_board()
	_events = events
	_next_event_index = 0
	_planned_duration = 0.0
	_board_view.show_board(_displayed_board)
	_tween = _board_view.create_tween()
	_queue_steps()
	_tween.tween_callback(_finish)
	_tween.set_speed_scale(maxf(1.0, _planned_duration / _config.max_chain_duration))


func skip() -> void:
	if not is_playing:
		return
	_tween.kill()
	_apply_events_until(_events.size())
	_finish()


func _queue_steps() -> void:
	var index: int = 0
	while index < _events.size():
		var event: ResolutionEvent = _events[index]
		if event is TilesPlacedEvent:
			_queue_drop(event as TilesPlacedEvent, index + 1)
			index += 1
		elif event is TilesFellEvent:
			_queue_fall(event as TilesFellEvent, index + 1)
			index += 1
		else:
			var link_end: int = _find_chain_link_end(index)
			_queue_chain_link(index, link_end)
			index = link_end


## Placed tiles enter at the top row, then drop to where they landed.
func _queue_drop(event: TilesPlacedEvent, events_end: int) -> void:
	var top_row: int = _displayed_board.row_count - 1
	var moving_tiles: Array[BoardView.MovingTile] = [
		BoardView.MovingTile.new(event.tile_level, Vector2i(event.tile_cell.x, top_row), event.tile_cell),
		BoardView.MovingTile.new(event.reflection_level, Vector2i(event.reflection_cell.x, top_row), event.reflection_cell),
	]
	_queue_movement(moving_tiles, [], events_end, _config.drop_duration)


func _queue_fall(event: TilesFellEvent, events_end: int) -> void:
	var moving_tiles: Array[BoardView.MovingTile] = []
	var origin_cells: Array[Vector2i] = []
	for fall: TileFall in event.falls:
		moving_tiles.append(BoardView.MovingTile.new(fall.level, fall.from_cell, fall.to_cell))
		origin_cells.append(fall.from_cell)
	_queue_movement(moving_tiles, origin_cells, events_end, _config.fall_duration)


## Tiles speed up as they fall, then squash on landing.
func _queue_movement(moving_tiles: Array[BoardView.MovingTile], hidden_cells: Array[Vector2i], events_end: int, duration: float) -> void:
	_tween.tween_callback(_board_view.start_moving_tiles.bind(moving_tiles, hidden_cells))
	_tween.tween_method(_board_view.set_move_progress, 0.0, 1.0, duration).set_trans(_config.fall_transition).set_ease(_config.fall_ease)
	_tween.tween_callback(_apply_events_until.bind(events_end))
	var landing_cells: Array[Vector2i] = []
	for moving_tile: BoardView.MovingTile in moving_tiles:
		landing_cells.append(moving_tile.to_cell)
	_tween.tween_callback(_board_view.start_tile_scale.bind(landing_cells, true))
	_tween.tween_method(_set_squash_progress, 0.0, 1.0, _config.landing_squash_duration)
	_queue_pause(duration + _config.landing_squash_duration)


## Every group of a chain link pulses, slides onto its result cell, then pops, at the same time.
## Later links play faster and pop larger.
func _queue_chain_link(link_start: int, link_end: int) -> void:
	var first_merge := _events[link_start] as GroupMergedEvent
	var speed: float = _config.get_chain_speed(first_merge.chain_link)
	var group_cells: Array[Vector2i] = []
	var converging_tiles: Array[BoardView.MovingTile] = []
	var converging_cells: Array[Vector2i] = []
	var result_cells: Array[Vector2i] = []
	var merges: Array[GroupMergedEvent] = []
	for index: int in range(link_start, link_end):
		var merge := _events[index] as GroupMergedEvent
		merges.append(merge)
		group_cells.append_array(merge.group_cells)
		result_cells.append(merge.result_cell)
		for cell: Vector2i in merge.group_cells:
			if cell != merge.result_cell:
				converging_tiles.append(BoardView.MovingTile.new(merge.group_level, cell, merge.result_cell))
				converging_cells.append(cell)
	var pulse_duration: float = _config.merge_pulse_duration / speed
	var converge_duration: float = _config.merge_converge_duration / speed
	var pop_duration: float = _config.merge_pop_duration / speed
	_tween.tween_callback(_show_chain_multiplier.bind(first_merge))
	_tween.tween_callback(_board_view.start_pulse.bind(group_cells))
	_tween.tween_method(_set_pulse_progress, 0.0, 1.0, pulse_duration)
	_tween.tween_callback(_board_view.start_moving_tiles.bind(converging_tiles, converging_cells))
	_tween.tween_method(_board_view.set_move_progress, 0.0, 1.0, converge_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_apply_events_until.bind(link_end))
	_tween.tween_callback(_burst_particles.bind(merges))
	_tween.tween_callback(_start_shake.bind(_config.get_shake_amplitude(first_merge.chain_link)))
	_queue_pop(result_cells, _config.get_pop_scale(first_merge.chain_link), pop_duration)
	_queue_pause(pulse_duration + converge_duration + pop_duration)


## Grows, then comes back with a small rebound below the tile size.
func _queue_pop(cells: Array[Vector2i], peak_scale: float, duration: float) -> void:
	var peak := Vector2.ONE * peak_scale
	_tween.tween_callback(_board_view.start_tile_scale.bind(cells, false))
	_tween.tween_method(_board_view.set_tile_scale, Vector2.ONE, peak, duration / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_board_view.set_tile_scale, peak, Vector2.ONE, duration / 2.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Ends a step: counts its duration, plus the pause that follows it.
func _queue_pause(step_duration: float) -> void:
	_tween.tween_interval(_config.step_pause)
	_planned_duration += step_duration + _config.step_pause


func _find_chain_link_end(link_start: int) -> int:
	var chain_link: int = (_events[link_start] as GroupMergedEvent).chain_link
	var index: int = link_start
	while index < _events.size() and _events[index] is GroupMergedEvent and (_events[index] as GroupMergedEvent).chain_link == chain_link:
		index += 1
	return index


## Each burst takes the result tile color of the active palette, so it follows the theme.
func _burst_particles(merges: Array[GroupMergedEvent]) -> void:
	var cell_width: float = _board_view.get_cell_width()
	for merge: GroupMergedEvent in merges:
		var color: Color = _board_view.tile_painter.palette.get_tile_color(merge.result_level)
		_particles.burst(_board_view.get_cell_center(merge.result_cell), color, _config.get_particle_count(merge.chain_link), cell_width)


## Runs beside the turn tween, so it never lengthens the turn.
func _start_shake(amplitude: float) -> void:
	if amplitude <= 0.0 or not Settings.is_screen_shake_enabled:
		return
	_stop_shake()
	_shake_tween = _board_view.create_tween()
	_shake_tween.tween_method(_set_shake_progress.bind(amplitude * _board_view.get_cell_width()), 0.0, 1.0, _config.shake_duration)
	_shake_tween.tween_callback(_stop_shake)


## A random offset each frame, fading out over the shake.
func _set_shake_progress(progress: float, amplitude: float) -> void:
	var direction := Vector2.from_angle(_shake_rng.randf() * TAU)
	_board_view.set_shake_offset(direction * amplitude * (1.0 - progress))


func _stop_shake() -> void:
	if _shake_tween != null:
		_shake_tween.kill()
		_shake_tween = null
	_board_view.set_shake_offset(Vector2.ZERO)


## Wider and shorter, then back to the tile size.
func _set_squash_progress(progress: float) -> void:
	var squash: float = _config.landing_squash * sin(progress * PI)
	_board_view.set_tile_scale(Vector2(1.0 + squash, 1.0 - squash))


## Rises and falls back once over the pulse.
func _set_pulse_progress(progress: float) -> void:
	_board_view.set_pulse_strength(sin(progress * PI))


func _show_chain_multiplier(merge: GroupMergedEvent) -> void:
	_chain_label.visible = merge.chain_link > 1
	_chain_label.text = tr("UI_CHAIN_MULTIPLIER").format({"value": String.num(merge.chain_multiplier)})


func _apply_events_until(events_end: int) -> void:
	while _next_event_index < events_end:
		_events[_next_event_index].apply_to(_displayed_board)
		_next_event_index += 1
	_board_view.clear_animation()


func _finish() -> void:
	if not is_playing:
		return
	is_playing = false
	_stop_shake()
	_chain_label.visible = false
	_board_view.clear_animation()
	playback_finished.emit()
