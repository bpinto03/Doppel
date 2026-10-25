class_name ResolutionPlayback
extends RefCounted

## Replays a turn's resolution events on a copy of the board taken before the turn.
## The session already holds the final state: skipping only fast-forwards the display.

signal playback_finished

var is_playing: bool

var _config: ResolutionPlaybackConfig
var _board_view: BoardView
var _chain_label: Label
var _displayed_board: BoardState
var _events: Array[ResolutionEvent]
var _next_event_index: int
var _tween: Tween
var _planned_duration: float


func _init(config: ResolutionPlaybackConfig, board_view: BoardView, chain_label: Label) -> void:
	_config = config
	_board_view = board_view
	_chain_label = chain_label


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
	var top_row: float = _displayed_board.row_count - 1
	var moving_tiles: Array[BoardView.MovingTile] = [
		BoardView.MovingTile.new(event.tile_cell.x, event.tile_level, top_row, event.tile_cell.y),
		BoardView.MovingTile.new(event.reflection_cell.x, event.reflection_level, top_row, event.reflection_cell.y),
	]
	_queue_movement(moving_tiles, [], events_end, _config.drop_duration)


func _queue_fall(event: TilesFellEvent, events_end: int) -> void:
	var moving_tiles: Array[BoardView.MovingTile] = []
	var origin_cells: Array[Vector2i] = []
	for fall: TileFall in event.falls:
		moving_tiles.append(BoardView.MovingTile.new(fall.to_cell.x, fall.level, fall.from_cell.y, fall.to_cell.y))
		origin_cells.append(fall.from_cell)
	_queue_movement(moving_tiles, origin_cells, events_end, _config.fall_duration)


func _queue_movement(moving_tiles: Array[BoardView.MovingTile], hidden_cells: Array[Vector2i], events_end: int, duration: float) -> void:
	_tween.tween_callback(_board_view.start_moving_tiles.bind(moving_tiles, hidden_cells))
	_tween.tween_method(_board_view.set_move_progress, 0.0, 1.0, duration)
	_queue_events_applied(events_end, duration)


## Every group of a chain link pulses, then merges, at the same time.
func _queue_chain_link(link_start: int, link_end: int) -> void:
	var group_cells: Array[Vector2i] = []
	for index: int in range(link_start, link_end):
		group_cells.append_array((_events[index] as GroupMergedEvent).group_cells)
	_tween.tween_callback(_show_chain_multiplier.bind(_events[link_start] as GroupMergedEvent))
	_tween.tween_callback(_board_view.start_pulse.bind(group_cells))
	_tween.tween_method(_set_pulse_progress, 0.0, 1.0, _config.merge_pulse_duration)
	_queue_events_applied(link_end, _config.merge_pulse_duration)


func _queue_events_applied(events_end: int, step_duration: float) -> void:
	_tween.tween_callback(_apply_events_until.bind(events_end))
	_tween.tween_interval(_config.step_pause)
	_planned_duration += step_duration + _config.step_pause


func _find_chain_link_end(link_start: int) -> int:
	var chain_link: int = (_events[link_start] as GroupMergedEvent).chain_link
	var index: int = link_start
	while index < _events.size() and _events[index] is GroupMergedEvent and (_events[index] as GroupMergedEvent).chain_link == chain_link:
		index += 1
	return index


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
	_chain_label.visible = false
	_board_view.clear_animation()
	playback_finished.emit()
