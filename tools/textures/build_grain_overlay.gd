extends SceneTree

## Turns a grayscale wood grain picture into the overlay a palette draws over its surfaces (surface_grain):
## each pixel is black where the grain is darker than its mean and white where it is lighter, its alpha the gap,
## so drawing it at an opacity darkens or lightens any color by at most that opacity.
## Usage: godot --headless --path . -s tools/textures/build_grain_overlay.gd -- <source.png> <overlay.png>

const OVERLAY_SIZE: int = 1024
## Gaps beyond this many standard deviations, rare thin lines, are clamped to full alpha.
const CLAMPED_DEVIATIONS: float = 3.0


func _initialize() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.size() != 2:
		push_error("Usage: -- <source.png> <overlay.png>")
		quit(1)
		return
	var source: Image = Image.load_from_file(arguments[0])
	source.convert(Image.FORMAT_L8)
	var overlay: Image = build_overlay(_crop_center(source, OVERLAY_SIZE))
	overlay.save_png(arguments[1])
	quit()


static func build_overlay(grain: Image) -> Image:
	var mean: float = _calculate_mean(grain)
	var full_gap: float = CLAMPED_DEVIATIONS * _calculate_deviation(grain, mean)
	var overlay := Image.create(grain.get_width(), grain.get_height(), false, Image.FORMAT_RGBA8)
	for y: int in grain.get_height():
		for x: int in grain.get_width():
			var gap: float = clampf((grain.get_pixel(x, y).r - mean) / full_gap, -1.0, 1.0)
			var tint: Color = Color.WHITE if gap > 0.0 else Color.BLACK
			overlay.set_pixel(x, y, Color(tint, absf(gap)))
	return overlay


static func _crop_center(image: Image, side: int) -> Image:
	var origin := Vector2i((image.get_width() - side) / 2, (image.get_height() - side) / 2)
	return image.get_region(Rect2i(origin, Vector2i(side, side)))


static func _calculate_mean(image: Image) -> float:
	var total: float = 0.0
	for y: int in image.get_height():
		for x: int in image.get_width():
			total += image.get_pixel(x, y).r
	return total / (image.get_width() * image.get_height())


static func _calculate_deviation(image: Image, mean: float) -> float:
	var total: float = 0.0
	for y: int in image.get_height():
		for x: int in image.get_width():
			total += pow(image.get_pixel(x, y).r - mean, 2.0)
	return sqrt(total / (image.get_width() * image.get_height()))
