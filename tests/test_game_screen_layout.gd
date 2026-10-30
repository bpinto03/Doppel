extends GutTest

const GAME_SCREEN_SCENE: PackedScene = preload("res://scenes/game/game_screen.tscn")
const TEST_SAVE_PATH: String = "user://test_game_screen_layout_save.cfg"

var _player_save_path: String


func before_each() -> void:
	_player_save_path = SaveManager.save_path
	SaveManager.save_path = TEST_SAVE_PATH
	DirAccess.remove_absolute(TEST_SAVE_PATH)
	SaveManager.load_save()
	Settings.is_music_enabled = false


func after_each() -> void:
	AudioManager.stop_music()
	DirAccess.remove_absolute(TEST_SAVE_PATH)
	SaveManager.save_path = _player_save_path
	SaveManager.load_save()
	AudioManager.apply_settings()


## Tests run in a debug build, so the debug buttons are shown and must not widen the screen.
## Measured on the margin container: the root Control does not report its children's minimum size.
func test_screen_fits_the_base_width_with_the_debug_tools_shown() -> void:
	var screen: Control = GAME_SCREEN_SCENE.instantiate()
	add_child_autofree(screen)
	var content: Control = screen.get_node("Margin")

	assert_true(screen.get_node("%DebugTools").visible)
	assert_lte(content.get_combined_minimum_size().x, float(ProjectSettings.get_setting("display/window/size/viewport_width")))
