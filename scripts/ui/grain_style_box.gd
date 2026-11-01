class_name GrainStyleBox
extends StyleBox

## A StyleBoxFlat with the palette grain over it (see SurfaceGrain). UiThemeBuilder wraps the opaque boxes of a
## palette with surface_grain in it; a script cannot add drawing to StyleBoxFlat itself.

var box: StyleBoxFlat
var grain_texture: Texture2D
var grain_opacity: float


func _init(flat_box: StyleBoxFlat = null, texture: Texture2D = null, opacity: float = 0.0) -> void:
	box = flat_box
	grain_texture = texture
	grain_opacity = opacity
	if box == null:
		return
	for side: Side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		set_content_margin(side, box.get_margin(side))


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	box.draw(to_canvas_item, rect)
	SurfaceGrain.draw_over_box(to_canvas_item, rect, box, grain_texture, grain_opacity)
