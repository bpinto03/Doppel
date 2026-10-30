class_name PaletteScreen
extends Control

## A full screen drawn with the active palette: interface theme and background, rebuilt when the theme changes.
## Expects %Background and %BackgroundImage nodes.

const BASE_THEME: Theme = preload("res://assets/themes/base_theme.tres")

@onready var _background: ColorRect = %Background
@onready var _background_image: TextureRect = %BackgroundImage


func _ready() -> void:
	Settings.palette_changed.connect(_apply_palette)
	_apply_palette()


## Called after the theme and background, for what else the screen draws with the palette.
func _apply_screen_palette(_palette: ThemePalette) -> void:
	pass


func _apply_palette() -> void:
	var palette: ThemePalette = Settings.get_palette()
	theme = UiThemeBuilder.build(palette, BASE_THEME)
	_background.color = palette.background
	_background_image.texture = palette.background_image
	_apply_screen_palette(palette)
