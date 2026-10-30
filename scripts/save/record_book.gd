class_name RecordBook
extends RefCounted

## Best score and highest tile level over every real game, in the record save section. They never go down.

const SECTION: String = "record"
const BEST_SCORE_KEY: String = "best_score"
const HIGHEST_LEVEL_KEY: String = "highest_level_reached"


static func get_best_score() -> int:
	return SaveManager.get_value(SECTION, BEST_SCORE_KEY, 0)


static func get_highest_level() -> int:
	return SaveManager.get_value(SECTION, HIGHEST_LEVEL_KEY, BoardState.EMPTY_CELL)


static func submit(session: GameSession) -> void:
	if session.score > get_best_score():
		SaveManager.set_value(SECTION, BEST_SCORE_KEY, session.score)
	if session.highest_level_reached > get_highest_level():
		SaveManager.set_value(SECTION, HIGHEST_LEVEL_KEY, session.highest_level_reached)
