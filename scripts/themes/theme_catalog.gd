class_name ThemeCatalog
extends Resource

## Every theme the game offers, in display order.

@export var entries: Array[ThemeEntry] = []
## Equipped when the saved theme is unknown or not owned; must be a free entry.
@export var default_id: StringName


func get_entries() -> Array[ThemeEntry]:
	return entries


func get_default_id() -> StringName:
	return default_id


## Null for an id not in the catalog.
func find_entry(id: StringName) -> ThemeEntry:
	for entry: ThemeEntry in entries:
		if entry.id == id:
			return entry
	return null
