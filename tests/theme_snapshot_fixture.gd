class_name ThemeSnapshotFixture
extends RefCounted

## Every value a palette gives the screens, as plain text: the interface theme it builds and the tile painting per level.
## tests/data/theme_snapshot_*.json keep these values for Paper and Night as they were before shop theme changes,
## so a new optional palette field can be shown to leave them untouched.

const BASE_THEME: Theme = preload("res://assets/themes/base_theme.tres")
const TILE_TEXT_CONFIG: TileTextConfig = preload("res://data/tile_text.tres")
const SNAPSHOT_PATH_FORMAT: String = "res://tests/data/theme_snapshot_%s.json"
const STYLE_BOX_PROPERTIES: Array[StringName] = [
	&"bg_color", &"draw_center", &"border_color", &"border_blend",
	&"border_width_left", &"border_width_top", &"border_width_right", &"border_width_bottom",
	&"corner_radius_top_left", &"corner_radius_top_right", &"corner_radius_bottom_right", &"corner_radius_bottom_left",
	&"shadow_color", &"shadow_size", &"shadow_offset",
	&"expand_margin_left", &"expand_margin_top", &"expand_margin_right", &"expand_margin_bottom",
	&"content_margin_left", &"content_margin_top", &"content_margin_right", &"content_margin_bottom",
	&"color", &"thickness", &"vertical", &"grow_begin", &"grow_end",
]


static func build(palette: ThemePalette) -> Dictionary[String, String]:
	var snapshot: Dictionary[String, String] = {}
	_add_theme(snapshot, UiThemeBuilder.build(palette, BASE_THEME))
	_add_tiles(snapshot, TilePainter.new(palette, TILE_TEXT_CONFIG))
	return snapshot


static func load_saved(palette_name: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(SNAPSHOT_PATH_FORMAT % palette_name))


static func _add_theme(snapshot: Dictionary[String, String], theme: Theme) -> void:
	for type: StringName in theme.get_type_list():
		var prefix: String = "theme/%s/" % type
		snapshot[prefix + "base"] = String(theme.get_type_variation_base(type))
		for name: StringName in theme.get_color_list(type):
			snapshot[prefix + "color/" + name] = str(theme.get_color(name, type))
		for name: StringName in theme.get_constant_list(type):
			snapshot[prefix + "constant/" + name] = str(theme.get_constant(name, type))
		for name: StringName in theme.get_font_size_list(type):
			snapshot[prefix + "font_size/" + name] = str(theme.get_font_size(name, type))
		for name: StringName in theme.get_font_list(type):
			snapshot[prefix + "font/" + name] = theme.get_font(name, type).resource_path
		for name: StringName in theme.get_stylebox_list(type):
			_add_style_box(snapshot, prefix + "stylebox/" + name, theme.get_stylebox(name, type))


static func _add_style_box(snapshot: Dictionary[String, String], key: String, style_box: StyleBox) -> void:
	snapshot[key + "/class"] = style_box.get_class()
	for property: StringName in STYLE_BOX_PROPERTIES:
		if property in style_box:
			snapshot[key + "/" + property] = str(style_box.get(property))


static func _add_tiles(snapshot: Dictionary[String, String], painter: TilePainter) -> void:
	for level: int in range(1, painter.palette.tile_colors.size() + 1):
		var prefix: String = "tile/%d/" % level
		snapshot[prefix + "text"] = str(painter.get_text_color(level))
		snapshot[prefix + "edge"] = str(painter.get_edge_color(level))
		snapshot[prefix + "outlined"] = str(painter.is_outlined(level))
