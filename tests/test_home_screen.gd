extends GutTest

const HOME_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/home_screen.tscn")
## Wider than half of any phone screen, as a long translation could be.
const LONG_TEXT_LENGTH: int = 80

var _home: HomeScreen


func before_each() -> void:
	_home = HOME_SCREEN_SCENE.instantiate()
	add_child_autofree(_home)
	await wait_process_frames(1)


func test_short_texts_put_play_left_of_continue() -> void:
	_home.show_choices(HomeMenu.get_choices(true))

	assert_false(_home.is_stacked())
	assert_eq(_get_button_order(), ["PlayButton", "ContinueButton"])


func test_texts_too_wide_for_half_the_screen_stack_continue_above_play() -> void:
	(_home.get_node("%PlayButton") as Button).text = "W".repeat(LONG_TEXT_LENGTH)

	_home.show_choices(HomeMenu.get_choices(true))

	assert_true(_home.is_stacked())
	assert_eq(_get_button_order(), ["ContinueButton", "PlayButton"])


func test_play_alone_hides_continue() -> void:
	_home.show_choices(HomeMenu.get_choices(false))

	assert_false(_home.is_choice_shown(HomeMenu.Choice.CONTINUE))
	assert_false(_home.is_stacked())


func _get_button_order() -> Array[String]:
	var names: Array[String] = []
	for button: Node in _home.get_node("%ChoiceButtons").get_children():
		names.append(button.name)
	return names
