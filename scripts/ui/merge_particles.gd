class_name MergeParticles
extends Node2D

## Fixed pool of one-shot emitters, reused from burst to burst, so a long chain never allocates
## nor exceeds the live particle cap.

const TEXTURE_SIZE: int = 16
## Spread is measured on each side of the direction, so this sends particles every way.
const ALL_DIRECTIONS_SPREAD: float = 180.0

static var _disc_texture: Texture2D = _create_disc_texture()

var _config: ResolutionPlaybackConfig
var _emitters: Array[CPUParticles2D] = []


func _init(config: ResolutionPlaybackConfig) -> void:
	_config = config
	for i: int in ceili(float(config.max_live_particles) / config.particles_per_merge):
		var emitter := CPUParticles2D.new()
		emitter.emitting = false
		emitter.one_shot = true
		emitter.explosiveness = 1.0
		emitter.texture = _disc_texture
		emitter.spread = ALL_DIRECTIONS_SPREAD
		emitter.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
		emitter.lifetime = config.particle_lifetime
		_emitters.append(emitter)
		add_child(emitter)


## The burst shrinks, or is dropped, when the live particle cap is reached.
func burst(center: Vector2, color: Color, amount: int, cell_width: float) -> void:
	var allowed_amount: int = mini(amount, _config.max_live_particles - get_live_particle_count())
	var emitter: CPUParticles2D = _find_idle_emitter()
	if allowed_amount <= 0 or emitter == null:
		return
	emitter.amount = allowed_amount
	emitter.position = center
	emitter.color = color
	emitter.emission_sphere_radius = _config.particle_start_radius * cell_width
	emitter.scale_amount_min = _config.particle_min_size * cell_width / TEXTURE_SIZE
	emitter.scale_amount_max = _config.particle_max_size * cell_width / TEXTURE_SIZE
	emitter.initial_velocity_min = _config.particle_min_speed * cell_width
	emitter.initial_velocity_max = _config.particle_max_speed * cell_width
	emitter.gravity = Vector2(0.0, _config.particle_gravity * cell_width)
	emitter.restart()


func get_live_particle_count() -> int:
	var count: int = 0
	for emitter: CPUParticles2D in _emitters:
		if emitter.emitting:
			count += emitter.amount
	return count


func _find_idle_emitter() -> CPUParticles2D:
	for emitter: CPUParticles2D in _emitters:
		if not emitter.emitting:
			return emitter
	return null


static func _create_disc_texture() -> Texture2D:
	var image := Image.create_empty(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	var radius: float = TEXTURE_SIZE / 2.0
	for x: int in TEXTURE_SIZE:
		for y: int in TEXTURE_SIZE:
			var distance: float = Vector2(x + 0.5, y + 0.5).distance_to(Vector2(radius, radius))
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, clampf(radius - distance, 0.0, 1.0)))
	return ImageTexture.create_from_image(image)
