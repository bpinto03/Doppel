class_name ThemeEntry
extends Resource

## One theme of the catalog. The id is saved (owned themes, equipped theme): never rename it.

@export var id: StringName
@export var palette: ThemePalette
## Free themes (price 0) are always owned.
@export var price: int
@export var display_name_key: String
