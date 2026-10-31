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

@export_group("HUD")
## Glows and soft shadows here and on the board are drawn in these colors; a transparent color removes one.
## Fill of the capsule holding the score and record panels.
@export var hud_capsule: Color
@export var hud_capsule_border: Color
@export var hud_capsule_glow: Color
## Fill of the score and record panels.
@export var hud_panel: Color
@export var hud_score_panel_border: Color
@export var hud_record_panel_border: Color
@export var hud_record_panel_glow: Color
@export var hud_separator: Color
@export var score_caption: Color
@export var record_caption: Color
@export var score_value_glow: Color
@export var record_value_glow: Color
@export var score_icon: Texture2D
@export var record_icon: Texture2D
@export var pause_button: Color
@export var pause_button_border: Color
@export var pause_symbol: Color

@export_group("Home")
## Logo fills are translucent, so their overlap shows through.
@export var logo_left_fill: Color
@export var logo_left_outline: Color
@export var logo_right_fill: Color
@export var logo_right_outline: Color
## Stars and dashes around the logo circles.
@export var logo_accent: Color
@export var logo_glow: Color
@export var title: Color
@export var title_glow: Color
## Play and Continue. A transparent glow removes it; a dark one makes a soft shadow.
@export var home_primary_button: Color
@export var home_primary_button_border: Color
@export var home_primary_button_glow: Color
@export var home_primary_badge: Color
@export var home_primary_icon: Color
## Also the chevron color, at lower opacity.
@export var home_primary_text: Color
## Tutorial and Settings.
@export var home_secondary_button: Color
@export var home_secondary_button_border: Color
@export var home_secondary_badge: Color
@export var home_secondary_icon: Color
@export var home_secondary_text: Color

@export_group("Pause")
## Covers the paused game behind the panel. The pause title takes the home title colors.
@export var pause_scrim: Color
@export var pause_panel: Color
@export var pause_panel_border: Color
@export var pause_panel_glow: Color
## Lines on both sides of the title; a transparent color hides them.
@export var pause_title_rule: Color
@export var pause_resume_button: Color
@export var pause_resume_button_border: Color
@export var pause_resume_button_glow: Color
@export var pause_resume_badge: Color
@export var pause_resume_icon: Color
@export var pause_resume_text: Color
## Menu, Restart, Settings and Back.
@export var pause_secondary_button: Color
@export var pause_secondary_button_border: Color
@export var pause_secondary_badge: Color
@export var pause_secondary_icon: Color
@export var pause_secondary_text: Color

@export_group("Board")
## Translucent fill of the board frame.
@export var frame_fill: Color
@export var frame_border: Color
@export var frame_glow: Color
@export var empty_cell: Color
## Thin light outline of empty cells.
@export var cell_outline: Color
@export var axis: Color
@export var axis_glow: Color
## Tutorial highlight of the target column, cells and axis.
@export var highlight: Color

@export_group("Tiles")
## Value text on light tiles.
@export var tile_text_dark: Color
## Value text on dark tiles.
@export var tile_text_light: Color
## Opacity of the glow around each tile, in its own color; 0 removes it, the first saving to try if the frame rate drops.
@export var tile_glow_opacity: float
## Least WCAG contrast of a tile against the empty cells and the frame; a tile below it gets an outline that reaches it.
@export var min_tile_edge_contrast: float
## One color per level, from level 1.
@export var tile_colors: Array[Color]


func get_tile_color(level: int) -> Color:
	return tile_colors[level - 1]


## The value text with the higher contrast on this level's tile. TilePainter keeps the answer for each level.
func pick_tile_text_color(level: int) -> Color:
	var tile_color: Color = get_tile_color(level)
	var dark_contrast: float = ColorContrast.calculate_ratio(tile_text_dark, tile_color)
	var light_contrast: float = ColorContrast.calculate_ratio(tile_text_light, tile_color)
	return tile_text_dark if dark_contrast >= light_contrast else tile_text_light
