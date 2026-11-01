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

@export_group("Modal")
## Pause and game over overlays. The scrim covers the game behind the panel; modal titles take the home title colors.
@export var modal_scrim: Color
@export var modal_panel: Color
@export var modal_panel_border: Color
@export var modal_panel_glow: Color
## Lines on both sides of the title; a transparent color hides them.
@export var modal_title_rule: Color
## Resume in the pause, Play again on the game over screen.
@export var modal_primary_button: Color
@export var modal_primary_button_border: Color
@export var modal_primary_button_glow: Color
@export var modal_primary_badge: Color
@export var modal_primary_icon: Color
@export var modal_primary_text: Color
## Menu, Restart, Settings and Back in the pause, Menu on the game over screen.
@export var modal_secondary_button: Color
@export var modal_secondary_button_border: Color
@export var modal_secondary_badge: Color
@export var modal_secondary_icon: Color
@export var modal_secondary_text: Color
## Tap icon beside the tutorial instruction; the tutorial text takes modal_secondary_text.
@export var tutorial_icon: Color

@export_group("Game over")
## Soft disc and rays behind the crown; a transparent color removes them.
@export var game_over_halo: Color
## Each stat row has its own tint; a transparent glow removes it.
@export var game_over_score_row: Color
@export var game_over_score_row_border: Color
@export var game_over_score_row_glow: Color
@export var game_over_record_row: Color
@export var game_over_record_row_border: Color
@export var game_over_record_row_glow: Color
## Record caption, and the new record message.
@export var game_over_record_caption: Color
@export var game_over_tile_row: Color
@export var game_over_tile_row_border: Color
@export var game_over_tile_row_glow: Color
@export var game_over_tile_icon: Color
@export var game_over_stat_caption: Color
@export var game_over_stat_value: Color
## Value color of each row; transparent, the default, keeps game_over_stat_value.
@export var game_over_score_value: Color = Color.TRANSPARENT
@export var game_over_record_value: Color = Color.TRANSPARENT
@export var game_over_tile_value: Color = Color.TRANSPARENT

@export_group("Coins")
## Coin counter on the home and game over screens; its text must keep a 4.5:1 contrast on its fill.
@export var coin_counter: Color
@export var coin_counter_border: Color
@export var coin_counter_text: Color
## "+N" coins earned, on the modal panel.
@export var coin_gain_text: Color

@export_group("Shop")
## Theme cards of the shop; every text keeps a 4.5:1 contrast on the fill it sits on.
@export var shop_card: Color
@export var shop_card_border: Color
@export var shop_card_glow: Color
## The card of the equipped theme: a tinted fill, a thicker accent border and its glow.
@export var shop_card_equipped: Color
@export var shop_card_equipped_border: Color
@export var shop_card_equipped_glow: Color
@export var shop_name_text: Color
## Card descriptions and the shop subtitle.
@export var shop_description_text: Color
## Equip and Buy fade from the highlight at the top to the base color below.
@export var shop_equip_button: Color
@export var shop_equip_button_highlight: Color
@export var shop_buy_button: Color
@export var shop_buy_button_highlight: Color
@export var shop_button_text: Color
## Equipped, and Buy with too few coins.
@export var shop_disabled_button: Color
@export var shop_disabled_text: Color
@export var shop_check_badge: Color
@export var shop_check_icon: Color

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
## Empty for none. Else one color per level, from level 1: a light rim all around each tile, without the relief,
## which decides instead of the tile color whether the tile stands out from the board.
@export var tile_rim_colors: Array[Color] = []


func has_tile_rims() -> bool:
	return not tile_rim_colors.is_empty()


func get_tile_color(level: int) -> Color:
	return tile_colors[level - 1]


## The value text with the higher contrast on this level's tile. TilePainter keeps the answer for each level.
func pick_tile_text_color(level: int) -> Color:
	var tile_color: Color = get_tile_color(level)
	var dark_contrast: float = ColorContrast.calculate_ratio(tile_text_dark, tile_color)
	var light_contrast: float = ColorContrast.calculate_ratio(tile_text_light, tile_color)
	return tile_text_dark if dark_contrast >= light_contrast else tile_text_light
