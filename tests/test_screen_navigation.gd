extends GutTest


func test_back_from_home_quits() -> void:
	for game_state: ScreenNavigation.GameState in ScreenNavigation.GameState.values():
		assert_eq(ScreenNavigation.resolve_back(ScreenNavigation.Screen.HOME, game_state), ScreenNavigation.BackAction.QUIT)


func test_back_from_the_tutorial_shows_home() -> void:
	assert_eq(
		ScreenNavigation.resolve_back(ScreenNavigation.Screen.GAME, ScreenNavigation.GameState.TUTORIAL),
		ScreenNavigation.BackAction.SHOW_HOME
	)


func test_back_from_a_game_shows_home() -> void:
	assert_eq(
		ScreenNavigation.resolve_back(ScreenNavigation.Screen.GAME, ScreenNavigation.GameState.PLAYING),
		ScreenNavigation.BackAction.SHOW_HOME
	)
