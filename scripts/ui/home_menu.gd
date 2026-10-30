class_name HomeMenu
extends RefCounted

## Which entries the home screen offers, and how they are laid out.

enum Choice { PLAY, CONTINUE }


static func get_choices(has_game_in_progress: bool) -> Array[Choice]:
	if has_game_in_progress:
		return [Choice.PLAY, Choice.CONTINUE]
	return [Choice.PLAY]


## Side by side, Play is on the left; stacked, Continue is on top.
static func order_choices(choices: Array[Choice], is_stacked: bool) -> Array[Choice]:
	var ordered: Array[Choice] = choices.duplicate()
	if is_stacked:
		ordered.reverse()
	return ordered


## Side by side buttons share the width equally, so the widest one sets the width they need.
static func should_stack(button_min_widths: Array[float], separation: float, available_width: float) -> bool:
	if button_min_widths.size() < 2:
		return false
	var needed_width: float = button_min_widths.max() * button_min_widths.size() + separation * (button_min_widths.size() - 1)
	return needed_width > available_width
