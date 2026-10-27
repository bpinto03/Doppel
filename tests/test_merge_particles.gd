extends GutTest

const LIVE_PARTICLE_CAP: int = 20
const BURST_AMOUNT: int = 15
const CELL_WIDTH: float = 100.0

var _particles: MergeParticles


func before_each() -> void:
	var config: ResolutionPlaybackConfig = preload("res://data/resolution_playback.tres").duplicate()
	config.max_live_particles = LIVE_PARTICLE_CAP
	_particles = MergeParticles.new(config)
	add_child_autofree(_particles)


func test_bursts_never_exceed_the_live_particle_cap() -> void:
	_particles.burst(Vector2.ZERO, Color.WHITE, BURST_AMOUNT, CELL_WIDTH)
	_particles.burst(Vector2.ZERO, Color.WHITE, BURST_AMOUNT, CELL_WIDTH)
	_particles.burst(Vector2.ZERO, Color.WHITE, BURST_AMOUNT, CELL_WIDTH)

	assert_eq(_particles.get_live_particle_count(), LIVE_PARTICLE_CAP)


func test_finished_bursts_free_their_particles() -> void:
	_particles.burst(Vector2.ZERO, Color.WHITE, BURST_AMOUNT, CELL_WIDTH)

	await wait_seconds(preload("res://data/resolution_playback.tres").particle_lifetime * 3.0)

	assert_eq(_particles.get_live_particle_count(), 0)
