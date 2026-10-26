extends GutTest

const PHONE_SIZE := Vector2i(1080, 2340)
const STATUS_BAR_HEIGHT: int = 90
const NAVIGATION_BAR_HEIGHT: int = 130


func test_full_safe_area_gives_no_insets() -> void:
	var viewport_size := Vector2(PHONE_SIZE)
	var safe_rect: Rect2 = SafeAreaMargin.compute_safe_rect(Rect2i(Vector2i.ZERO, PHONE_SIZE), PHONE_SIZE, viewport_size)

	assert_eq(SafeAreaMargin.compute_insets(safe_rect, viewport_size), [0, 0, 0, 0])


func test_system_bars_become_top_and_bottom_insets() -> void:
	var viewport_size := Vector2(PHONE_SIZE)
	var safe_rect: Rect2 = SafeAreaMargin.compute_safe_rect(_create_safe_area_between_bars(), PHONE_SIZE, viewport_size)

	assert_eq(SafeAreaMargin.compute_insets(safe_rect, viewport_size), [0, STATUS_BAR_HEIGHT, 0, NAVIGATION_BAR_HEIGHT])


func test_insets_are_converted_to_viewport_units() -> void:
	var viewport_size := Vector2(PHONE_SIZE) / 2.0
	var safe_rect: Rect2 = SafeAreaMargin.compute_safe_rect(_create_safe_area_between_bars(), PHONE_SIZE, viewport_size)

	assert_eq(SafeAreaMargin.compute_insets(safe_rect, viewport_size), [0, STATUS_BAR_HEIGHT / 2, 0, NAVIGATION_BAR_HEIGHT / 2])


func _create_safe_area_between_bars() -> Rect2i:
	var safe_height: int = PHONE_SIZE.y - STATUS_BAR_HEIGHT - NAVIGATION_BAR_HEIGHT
	return Rect2i(0, STATUS_BAR_HEIGHT, PHONE_SIZE.x, safe_height)
