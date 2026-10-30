class_name CurrentGameStore
extends RefCounted

## The saved game in progress, in its own save section. The tutorial is never stored.

const SECTION: String = "current_game"


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
