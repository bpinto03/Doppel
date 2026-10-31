class_name ThemePalette
extends Resource

## Colors of one visual theme. See docs/decisions/0003-art-direction.md.

@export_group("Screen")
@export var background: Color
## Covers the screen over the background color; the color shows where the image is transparent or missing.
@export var background_image: Texture2D
@export var text: Color
@export var panel: Color
@export var button: Color
@export var button_text: Color
## Border of the pause button.
@export var panel_border: Color
## Opacity of the glows around the HUD panels and values; 0 removes them.
@export var glow_opacity: float

@export_group("HUD")
## Translucent fill of the capsule holding the score and record panels.
@export var hud_capsule: Color
## Fill of the score and record panels and of the pause button.
@export var hud_panel: Color
## Capsule border and score glow.
@export var score_accent: Color
## Record panel border and record glow.
@export var record_accent: Color
@export var score_caption: Color
@export var record_caption: Color

@export_group("Board")
@export var empty_cell: Color
@export var axis: Color
## Tutorial highlight of the target column, cells and axis.
@export var highlight: Color

@export_group("Tiles")
## Value text, the same on every tile so all tiles share one contrast rule.
@export var tile_text: Color
## One color per level, from level 1.
@export var tile_colors: Array[Color]


func get_tile_color(level: int) -> Color:
	return tile_colors[level - 1]
