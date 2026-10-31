class_name CurrentGameStore
extends RefCounted

## The saved game in progress, in its own save section. The tutorial is never stored.

const SECTION: String = "current_game"
## Kept with the game, so the game over screen can tell a beaten record even after the game was resumed.
const BEST_SCORE_BEFORE_GAME_KEY: String = "best_score_before_game"


## Returns null when no game is saved. A saved game that cannot be restored is discarded; the rest of the save is kept.
static func load_session(config: BalancingConfig) -> GameSession:
	var data: Dictionary[String, Variant] = SaveManager.get_section(SECTION)
	if data.is_empty():
		return null
	var session: GameSession = GameSession.create_from_data(config, data)
	if session == null:
		push_warning("Saved game in progress discarded: damaged, finished, or made under other rules")
		SaveManager.erase_section(SECTION)
	return session


static func store(session: GameSession, best_score_before_game: int) -> void:
	var data: Dictionary[String, Variant] = session.to_data()
	data[BEST_SCORE_BEFORE_GAME_KEY] = best_score_before_game
	SaveManager.set_section(SECTION, data)


## A save from before this key existed gives the current record, so no record is announced as beaten.
static func load_best_score_before_game() -> int:
	return SaveManager.get_value(SECTION, BEST_SCORE_BEFORE_GAME_KEY, RecordBook.get_best_score())


static func erase() -> void:
	SaveManager.erase_section(SECTION)
