class_name ThemePalette
extends Resource

## Colors of one visual theme. See docs/decisions/0003-art-direction.md.

@export_group("Screen")
@export var background: Color
@export var text: Color
@export var panel: Color
@export var button: Color
@export var button_text: Color

@export_group("Board")
@export var empty_cell: Color
@export var axis: Color
## Tutorial highlight of the target column, cells and axis.
@export var highlight: Color

@export_group("Tiles")
## Value text and symbols, the same on every tile so all tiles share one contrast rule.
@export var tile_text: Color
## One color per level, from level 1.
@export var tile_colors: Array[Color]


func get_tile_color(level: int) -> Color:
	return tile_colors[level - 1]
