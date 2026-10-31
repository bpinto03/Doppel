class_name ScreenNavigation
extends RefCounted

## Where Play and the Android back button lead, and when the game pauses by itself.
## Main and GameScreen apply the answers; they never decide them. See docs/decisions/0006-back-button-and-overlays.md.

enum Screen { HOME, GAME, SETTINGS }
enum GameState { PLAYING, PAUSED, PAUSE_SETTINGS, TUTORIAL, GAME_OVER }
enum BackAction { QUIT, SHOW_HOME, OPEN_PAUSE, CLOSE_PAUSE, CLOSE_PAUSE_SETTINGS }
enum PlayAction { TUTORIAL, NEW_GAME }


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
		GameState.PAUSE_SETTINGS:
			return BackAction.CLOSE_PAUSE_SETTINGS
	return BackAction.SHOW_HOME


## The tutorial opens on Play until the player finished or skipped it once, in any launch.
static func resolve_play(has_seen_tutorial: bool) -> PlayAction:
	return PlayAction.NEW_GAME if has_seen_tutorial else PlayAction.TUTORIAL


## Only a real game in progress pauses: the tutorial, the game over screen and, later, ads also lose the focus.
static func should_pause_when_inactive(game_state: GameState) -> bool:
	return game_state == GameState.PLAYING
