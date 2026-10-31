class_name PlayerProgress
extends RefCounted

## What the player has done once and for all, in the progress save section. A missing key means not done yet.

const SECTION: String = "progress"
const HAS_SEEN_TUTORIAL_KEY: String = "has_seen_tutorial"


static func has_seen_tutorial() -> bool:
	return SaveManager.get_value(SECTION, HAS_SEEN_TUTORIAL_KEY, false)


static func mark_tutorial_seen() -> void:
	SaveManager.set_value(SECTION, HAS_SEEN_TUTORIAL_KEY, true)
