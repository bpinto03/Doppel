extends GutTest


func test_requested_and_enabled_music_plays_while_the_app_is_active() -> void:
	assert_eq(_create_state(true, true, true).get_action(), MusicState.Action.PLAY)


func test_music_pauses_while_the_app_is_in_the_background() -> void:
	assert_eq(_create_state(true, true, false).get_action(), MusicState.Action.PAUSE)


func test_disabled_music_stops_even_when_requested() -> void:
	assert_eq(_create_state(false, true, true).get_action(), MusicState.Action.STOP)
	assert_eq(_create_state(false, true, false).get_action(), MusicState.Action.STOP)


func test_music_stops_when_no_screen_requests_it() -> void:
	assert_eq(_create_state(true, false, true).get_action(), MusicState.Action.STOP)
	assert_eq(_create_state(true, false, false).get_action(), MusicState.Action.STOP)


func test_music_is_not_requested_by_default() -> void:
	var state := MusicState.new()
	state.is_enabled = true

	assert_eq(state.get_action(), MusicState.Action.STOP)


func _create_state(is_enabled: bool, is_requested: bool, is_app_active: bool) -> MusicState:
	var state := MusicState.new()
	state.is_enabled = is_enabled
	state.is_requested = is_requested
	state.is_app_active = is_app_active
	return state
