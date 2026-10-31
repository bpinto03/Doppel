extends GutTest


func test_back_from_home_quits() -> void:
	for game_state: ScreenNavigation.GameState in ScreenNavigation.GameState.values():
		assert_eq(ScreenNavigation.resolve_back(ScreenNavigation.Screen.HOME, game_state), ScreenNavigation.BackAction.QUIT)


func test_back_from_the_tutorial_shows_home() -> void:
	assert_eq(
		ScreenNavigation.resolve_back(ScreenNavigation.Screen.GAME, ScreenNavigation.GameState.TUTORIAL),
		ScreenNavigation.BackAction.SHOW_HOME
	)


func test_back_in_a_game_opens_the_pause() -> void:
	assert_eq(
		ScreenNavigation.resolve_back(ScreenNavigation.Screen.GAME, ScreenNavigation.GameState.PLAYING),
		ScreenNavigation.BackAction.OPEN_PAUSE
	)


func test_back_in_the_pause_resumes() -> void:
	assert_eq(
		ScreenNavigation.resolve_back(ScreenNavigation.Screen.GAME, ScreenNavigation.GameState.PAUSED),
		ScreenNavigation.BackAction.CLOSE_PAUSE
	)


func test_only_a_game_in_progress_pauses_when_the_app_is_inactive() -> void:
	assert_true(ScreenNavigation.should_pause_when_inactive(ScreenNavigation.GameState.PLAYING))
	for game_state: ScreenNavigation.GameState in [
		ScreenNavigation.GameState.PAUSED,
		ScreenNavigation.GameState.PAUSE_SETTINGS,
		ScreenNavigation.GameState.TUTORIAL,
		ScreenNavigation.GameState.GAME_OVER,
	]:
		assert_false(ScreenNavigation.should_pause_when_inactive(game_state))


func test_back_from_the_game_over_screen_shows_home() -> void:
	assert_eq(
		ScreenNavigation.resolve_back(ScreenNavigation.Screen.GAME, ScreenNavigation.GameState.GAME_OVER),
		ScreenNavigation.BackAction.SHOW_HOME
	)


func test_back_from_the_settings_shows_home() -> void:
	for game_state: ScreenNavigation.GameState in ScreenNavigation.GameState.values():
		assert_eq(ScreenNavigation.resolve_back(ScreenNavigation.Screen.SETTINGS, game_state), ScreenNavigation.BackAction.SHOW_HOME)


func test_back_in_the_pause_settings_returns_to_the_pause() -> void:
	assert_eq(
		ScreenNavigation.resolve_back(ScreenNavigation.Screen.GAME, ScreenNavigation.GameState.PAUSE_SETTINGS),
		ScreenNavigation.BackAction.CLOSE_PAUSE_SETTINGS
	)
