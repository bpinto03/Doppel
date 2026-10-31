class_name ScreenNavigation
extends RefCounted

## Where the Android back button leads from each screen and game state, and when the game pauses by itself.
## Main and GameScreen apply the answers; they never decide them. See docs/decisions/0006-back-button-and-overlays.md.

enum Screen { HOME, GAME, SETTINGS }
enum GameState { PLAYING, PAUSED, TUTORIAL, GAME_OVER }
enum BackAction { QUIT, SHOW_HOME, OPEN_PAUSE, CLOSE_PAUSE }


static func resolve_back(screen: Screen, game_state: GameState) -> BackAction:
	match screen:
		Screen.HOME:
			return BackAction.QUIT
		Screen.SETTINGS:
			return BackAction.SHOW_HOME
	match game_state:
		GameState.PLAYING:
			return BackAction.OPEN_PAUSE
		GameState.PAUSED:
			return BackAction.CLOSE_PAUSE
	return BackAction.SHOW_HOME


## Only a real game in progress pauses: the tutorial, the game over screen and, later, ads also lose the focus.
static func should_pause_when_inactive(game_state: GameState) -> bool:
	return game_state == GameState.PLAYING
