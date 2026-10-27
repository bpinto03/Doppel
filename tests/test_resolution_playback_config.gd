extends GutTest

const CONFIG: ResolutionPlaybackConfig = preload("res://data/resolution_playback.tres")
const LONG_CHAIN_LINK: int = 20


func test_chain_intensity_rises_with_the_link_up_to_its_cap() -> void:
	var previous_intensity: float = CONFIG.get_chain_intensity(1)
	for chain_link: int in range(2, CONFIG.chain_intensity_max_link + 1):
		var intensity: float = CONFIG.get_chain_intensity(chain_link)
		assert_gt(intensity, previous_intensity, "link %d" % chain_link)
		previous_intensity = intensity

	assert_eq(CONFIG.get_chain_intensity(LONG_CHAIN_LINK), CONFIG.get_chain_intensity(CONFIG.chain_intensity_max_link))


func test_pop_and_speed_stay_within_their_limits() -> void:
	assert_almost_eq(CONFIG.get_pop_scale(1), CONFIG.merge_pop_scale, 0.001)
	assert_almost_eq(CONFIG.get_chain_speed(1), 1.0, 0.001)
	assert_almost_eq(CONFIG.get_pop_scale(LONG_CHAIN_LINK), CONFIG.merge_pop_max_scale, 0.001)
	assert_almost_eq(CONFIG.get_chain_speed(LONG_CHAIN_LINK), CONFIG.chain_max_speed_up, 0.001)


func test_particle_count_rises_with_the_link_up_to_its_cap() -> void:
	assert_eq(CONFIG.get_particle_count(1), CONFIG.particles_per_merge)
	assert_gt(CONFIG.get_particle_count(2), CONFIG.get_particle_count(1))
	assert_eq(CONFIG.get_particle_count(LONG_CHAIN_LINK), CONFIG.max_particles_per_burst)


func test_shake_starts_at_its_link_then_grows_up_to_its_cap() -> void:
	assert_eq(CONFIG.get_shake_amplitude(CONFIG.shake_min_link - 1), 0.0)
	assert_eq(CONFIG.get_shake_amplitude(CONFIG.shake_min_link), CONFIG.shake_amplitude)
	assert_gt(CONFIG.get_shake_amplitude(CONFIG.shake_min_link + 1), CONFIG.shake_amplitude)
	assert_eq(CONFIG.get_shake_amplitude(LONG_CHAIN_LINK), CONFIG.shake_max_amplitude)
