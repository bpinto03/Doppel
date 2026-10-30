class_name MusicState
extends RefCounted

## Whether the ambient music plays, waits paused in the background, or is stopped with its stream released.

enum Action { PLAY, PAUSE, STOP }

var is_enabled: bool
var is_app_active: bool = true
## A screen asked for the music.
var is_requested: bool


func get_action() -> Action:
	if not is_enabled or not is_requested:
		return Action.STOP
	if not is_app_active:
		return Action.PAUSE
	return Action.PLAY
