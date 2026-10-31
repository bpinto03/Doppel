class_name ScreenNavigation
extends RefCounted

## Where the Android back button leads from each screen and game state. Main and GameScreen apply the answer; they never decide it.

enum Screen { HOME, GAME }
enum GameState { PLAYING, TUTORIAL }
enum BackAction { QUIT, SHOW_HOME }


static func resolve_back(screen: Screen, _game_state: GameState) -> BackAction:
	if screen == Screen.HOME:
		return BackAction.QUIT
	return BackAction.SHOW_HOME
