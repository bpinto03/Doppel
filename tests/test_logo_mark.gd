extends GutTest

const TEST_SAVE_PATH: String = "user://test_logo_mark_save.cfg"
const LOGO_SIZE := Vector2(480.0, 364.0)
const IDLE_FRAME_COUNT: int = 5

var _save := SaveFixture.new(TEST_SAVE_PATH)
var _logo: LogoMark
var _draw_count: int = 0


func before_each() -> void:
	_save.use_test_save()
	Settings.palette_name = "paper"
	_logo = LogoMark.new()
	_logo.size = LOGO_SIZE
	add_child_autofree(_logo)
	_logo.draw.connect(func() -> void: _draw_count += 1)
	await wait_process_frames(2)
	_draw_count = 0


func after_each() -> void:
	_save.restore_player_save()


func test_logo_is_not_redrawn_while_nothing_changes() -> void:
	await wait_process_frames(IDLE_FRAME_COUNT)

	assert_eq(_draw_count, 0)


func test_logo_is_redrawn_once_when_the_palette_changes() -> void:
	Settings.palette_name = "night"
	await wait_process_frames(IDLE_FRAME_COUNT)

	assert_eq(_draw_count, 1)


func test_logo_is_redrawn_once_when_resized() -> void:
	_logo.size = LOGO_SIZE * 2.0
	await wait_process_frames(IDLE_FRAME_COUNT)

	assert_eq(_draw_count, 1)
