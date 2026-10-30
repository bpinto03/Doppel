extends GutTest

const SEPARATION: float = 40.0


func test_no_game_in_progress_offers_play_only() -> void:
	assert_eq(HomeMenu.get_choices(false), [HomeMenu.Choice.PLAY])


func test_game_in_progress_offers_play_and_continue() -> void:
	assert_eq(HomeMenu.get_choices(true), [HomeMenu.Choice.PLAY, HomeMenu.Choice.CONTINUE])


func test_side_by_side_puts_play_on_the_left() -> void:
	assert_eq(HomeMenu.order_choices(HomeMenu.get_choices(true), false), [HomeMenu.Choice.PLAY, HomeMenu.Choice.CONTINUE])


func test_stacked_puts_continue_on_top() -> void:
	assert_eq(HomeMenu.order_choices(HomeMenu.get_choices(true), true), [HomeMenu.Choice.CONTINUE, HomeMenu.Choice.PLAY])


func test_buttons_stay_side_by_side_when_twice_the_widest_fits() -> void:
	assert_false(HomeMenu.should_stack([300.0, 420.0], SEPARATION, 420.0 * 2 + SEPARATION))


func test_buttons_stack_when_twice_the_widest_does_not_fit() -> void:
	assert_true(HomeMenu.should_stack([300.0, 420.0], SEPARATION, 420.0 * 2 + SEPARATION - 1.0))


func test_single_button_never_stacks() -> void:
	assert_false(HomeMenu.should_stack([2000.0], SEPARATION, 100.0))
