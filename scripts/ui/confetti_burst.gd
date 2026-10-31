class_name ConfettiBurst
extends Node2D

## One-shot burst of spinning confetti in the tile colors, thrown upward from a line and falling back.
## A single emitter, reused from burst to burst; nothing runs once its particles are gone.

## Confetti pieces are twice as long as wide.
const TEXTURE_SIZE := Vector2i(16, 8)
const CORNER_RADIUS: float = 3.0
const UP := Vector2(0.0, -1.0)
const FULL_TURN_DEGREES: float = 180.0

static var _piece_texture: Texture2D = _create_piece_texture()

var _config: GameOverEffectsConfig
var _emitter := CPUParticles2D.new()


func _init(config: GameOverEffectsConfig) -> void:
	_config = config
	_emitter.emitting = false
	_emitter.one_shot = true
	_emitter.explosiveness = 1.0
	_emitter.texture = _piece_texture
	_emitter.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_emitter.direction = UP
	_emitter.spread = config.confetti_spread
	_emitter.lifetime = config.confetti_lifetime
	_emitter.initial_velocity_min = config.confetti_min_speed
	_emitter.initial_velocity_max = config.confetti_max_speed
	_emitter.gravity = Vector2(0.0, config.confetti_gravity)
	_emitter.scale_amount_min = config.confetti_min_size / TEXTURE_SIZE.x
	_emitter.scale_amount_max = config.confetti_max_size / TEXTURE_SIZE.x
	_emitter.angle_min = -FULL_TURN_DEGREES
	_emitter.angle_max = FULL_TURN_DEGREES
	_emitter.angular_velocity_min = -config.confetti_max_spin
	_emitter.angular_velocity_max = config.confetti_max_spin
	add_child(_emitter)


## Pieces leave from a horizontal line centered on origin.
func place_line(origin: Vector2, line_width: float) -> void:
	_emitter.position = origin
	_emitter.emission_rect_extents = Vector2(line_width / 2.0, 0.0)


func burst(colors: Array[Color], is_record: bool) -> void:
	_emitter.amount = _config.record_confetti_amount if is_record else _config.confetti_amount
	_emitter.color_initial_ramp = _create_color_pick(colors)
	_emitter.visible = true
	_emitter.restart()


## Removes every piece at once, so none shows over what comes next.
func clear() -> void:
	_emitter.restart()
	_emitter.emitting = false
	_emitter.visible = false


func is_showing_confetti() -> bool:
	return _emitter.emitting and _emitter.is_visible_in_tree()


func get_amount() -> int:
	return _emitter.amount


func get_line_origin() -> Vector2:
	return _emitter.position


## Each piece takes one of the colors at random: constant interpolation turns the ramp into equal steps.
static func _create_color_pick(colors: Array[Color]) -> Gradient:
	var gradient := Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	gradient.offsets = PackedFloat32Array(range(colors.size()).map(func(index: int) -> float: return float(index) / colors.size()))
	gradient.colors = PackedColorArray(colors)
	return gradient


static func _create_piece_texture() -> Texture2D:
	var image := Image.create_empty(TEXTURE_SIZE.x, TEXTURE_SIZE.y, false, Image.FORMAT_RGBA8)
	var half_size := Vector2(TEXTURE_SIZE) / 2.0
	for x: int in TEXTURE_SIZE.x:
		for y: int in TEXTURE_SIZE.y:
			var from_center: Vector2 = (Vector2(x + 0.5, y + 0.5) - half_size).abs()
			var outside: Vector2 = (from_center - half_size + Vector2(CORNER_RADIUS, CORNER_RADIUS)).max(Vector2.ZERO)
			var distance: float = outside.length() - CORNER_RADIUS
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, clampf(0.5 - distance, 0.0, 1.0)))
	return ImageTexture.create_from_image(image)
