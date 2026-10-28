extends GutTest

const AUDIO_CONFIG: AudioConfig = preload("res://data/audio_config.tres")
const MAJOR_PENTATONIC: Array[int] = [2, 2, 3, 2, 3]
const SEMITONES_PER_OCTAVE: float = 12.0
const PITCH_TOLERANCE: float = 0.0001
const C_ROOT: int = 0
## merge.wav measures 737.69 Hz (F#5); C5 is 523.25 Hz.
const MERGE_SOUND_SEMITONES_ABOVE_C: float = 5.946
const MERGE_SOUND_PITCH_SCALE_IN_C: float = 0.7093


func test_first_link_plays_the_root_of_the_scale() -> void:
	assert_eq(_create_config(20, 48).get_chain_semitones(1), 0)


func test_links_climb_the_scale_intervals_in_order() -> void:
	var config: AudioConfig = _create_config(20, 48)

	assert_eq(config.get_chain_semitones(2), 2)
	assert_eq(config.get_chain_semitones(3), 4)
	assert_eq(config.get_chain_semitones(4), 7)
	assert_eq(config.get_chain_semitones(5), 9)
	assert_eq(config.get_chain_semitones(6), 12)


func test_scale_repeats_after_its_last_interval() -> void:
	var config: AudioConfig = _create_config(20, 48)

	assert_eq(config.get_chain_semitones(7), 14)
	assert_eq(config.get_chain_semitones(11), 24)


func test_pitch_stops_climbing_after_the_max_pitch_link() -> void:
	var config: AudioConfig = _create_config(4, 48)

	assert_eq(config.get_chain_semitones(4), 7)
	assert_eq(config.get_chain_semitones(9), 7)


func test_pitch_never_climbs_above_the_semitone_cap() -> void:
	var config: AudioConfig = _create_config(20, 10)

	assert_eq(config.get_chain_semitones(5), 9)
	assert_eq(config.get_chain_semitones(6), 10)
	assert_eq(config.get_chain_semitones(15), 10)


func test_key_of_c_tunes_the_merge_sound_down_to_c() -> void:
	var config: AudioConfig = _create_config(20, 48)

	assert_almost_eq(config.get_chain_pitch_scale(1), MERGE_SOUND_PITCH_SCALE_IN_C, PITCH_TOLERANCE)
	assert_almost_eq(config.get_chain_pitch_scale(6), MERGE_SOUND_PITCH_SCALE_IN_C * 2.0, PITCH_TOLERANCE)
	assert_almost_eq(config.get_chain_pitch_scale(2), MERGE_SOUND_PITCH_SCALE_IN_C * pow(2.0, 2.0 / SEMITONES_PER_OCTAVE), PITCH_TOLERANCE)


func test_game_over_plays_as_recorded_in_c() -> void:
	assert_eq(_create_config(20, 48).get_game_over_pitch_scale(), 1.0)


func test_game_over_goes_down_to_the_root_below_c() -> void:
	var config: AudioConfig = _create_config(20, 48)
	config.scale_root_semitones = 2

	assert_almost_eq(config.get_game_over_pitch_scale(), pow(2.0, -10.0 / SEMITONES_PER_OCTAVE), PITCH_TOLERANCE)


func test_first_link_plays_the_merge_sound_and_later_links_the_chain_sound() -> void:
	assert_eq(AUDIO_CONFIG.get_chain_link_effect(1), AUDIO_CONFIG.merge)
	assert_eq(AUDIO_CONFIG.get_chain_link_effect(2), AUDIO_CONFIG.chain)


## Any random pitch would put chain notes out of tune.
func test_chain_sounds_have_no_pitch_variation() -> void:
	assert_eq(AUDIO_CONFIG.merge.pitch_variation_percent, 0.0)
	assert_eq(AUDIO_CONFIG.chain.pitch_variation_percent, 0.0)


func test_game_config_climbs_the_major_pentatonic_scale_up_to_two_octaves() -> void:
	assert_eq(AUDIO_CONFIG.chain_scale_intervals, MAJOR_PENTATONIC)
	assert_eq(AUDIO_CONFIG.chain_max_semitones, 24)


func _create_config(max_pitch_link: int, max_semitones: int) -> AudioConfig:
	var config := AudioConfig.new()
	config.scale_root_semitones = C_ROOT
	config.merge_sound_semitones_above_c = MERGE_SOUND_SEMITONES_ABOVE_C
	config.chain_scale_intervals = MAJOR_PENTATONIC
	config.chain_max_pitch_link = max_pitch_link
	config.chain_max_semitones = max_semitones
	return config
