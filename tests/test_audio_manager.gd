extends GutTest

const TEST_SAVE_PATH: String = "user://test_audio_manager_save.cfg"
const AUDIO_MANAGER_SCRIPT: GDScript = preload("res://scripts/autoload/audio_manager.gd")
const HALF_VOLUME: float = 0.5
const DECIBEL_TOLERANCE: float = 0.01
## Players store their pitch in single precision.
const PITCH_TOLERANCE: float = 0.000001

var _player_save_path: String


func before_each() -> void:
	_player_save_path = SaveManager.save_path
	SaveManager.save_path = TEST_SAVE_PATH
	DirAccess.remove_absolute(TEST_SAVE_PATH)
	SaveManager.load_save()


func after_each() -> void:
	DirAccess.remove_absolute(TEST_SAVE_PATH)
	SaveManager.save_path = _player_save_path
	SaveManager.load_save()
	AudioManager.apply_settings()


func test_saved_disabled_sound_mutes_the_effect_bus_at_startup() -> void:
	# Written to the save directly, so no settings change notifies the running manager.
	SaveManager.set_value(Settings.SECTION, "is_sound_enabled", false)
	SaveManager.set_value(Settings.SECTION, "is_music_enabled", false)

	add_child_autofree(AUDIO_MANAGER_SCRIPT.new())

	assert_true(_is_bus_muted(AudioManager.SFX_BUS))
	assert_true(_is_bus_muted(AudioManager.MUSIC_BUS))
	assert_false(_is_bus_muted(AudioManager.MASTER_BUS))


func test_enabled_sound_leaves_the_effect_bus_audible() -> void:
	AudioManager.apply_settings()

	assert_false(_is_bus_muted(AudioManager.SFX_BUS))


func test_bus_volume_is_applied_in_decibels() -> void:
	Settings.set_bus_volume(AudioManager.SFX_BUS, HALF_VOLUME)

	assert_almost_eq(_get_bus_volume_db(AudioManager.SFX_BUS), linear_to_db(HALF_VOLUME), DECIBEL_TOLERANCE)
	assert_false(_is_bus_muted(AudioManager.SFX_BUS))


func test_zero_volume_mutes_the_bus() -> void:
	Settings.set_bus_volume(AudioManager.MUSIC_BUS, 0.0)

	assert_true(_is_bus_muted(AudioManager.MUSIC_BUS))


func test_disabled_music_loads_nothing_when_a_screen_starts_it() -> void:
	Settings.is_music_enabled = false

	AudioManager.start_music()

	assert_false(AudioManager.is_music_loaded())
	AudioManager.stop_music()


func test_missing_music_file_loads_no_stream() -> void:
	var config := AudioConfig.new()
	config.music_path = "res://assets/audio/music/missing_music.ogg"

	assert_null(config.load_music())


func _is_bus_muted(bus_name: StringName) -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(bus_name))


func _get_bus_volume_db(bus_name: StringName) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name))


func test_missing_effect_or_sound_plays_nothing_without_error() -> void:
	assert_null(AudioManager.play_effect(null))
	assert_null(AudioManager.play_effect(SoundEffect.new()))


func test_chain_link_plays_at_the_exact_scale_pitch() -> void:
	var config: AudioConfig = AudioManager.CONFIG
	var chain_link: int = 3

	var player: AudioStreamPlayer = AudioManager.play_effect(config.get_chain_link_effect(chain_link), config.get_chain_pitch_scale(chain_link))

	assert_almost_eq(player.pitch_scale, config.get_chain_pitch_scale(chain_link), PITCH_TOLERANCE)
	assert_eq(player.bus, AudioManager.SFX_BUS)
	player.stop()


func test_many_effects_reuse_the_same_players() -> void:
	var player_count: int = AudioManager.get_effect_player_count()

	for index: int in player_count * 3:
		AudioManager.play_effect(AudioManager.CONFIG.placement)

	assert_eq(AudioManager.get_effect_player_count(), AudioManager.CONFIG.player_pool_size)
	assert_eq(AudioManager.get_child_count(), player_count + 1)
