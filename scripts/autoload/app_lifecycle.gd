extends Node

## Whether the app is in the foreground with focus. Going to the background, a screen lock, an incoming call,
## a notification shade or, later, a full-screen ad all make it inactive: listeners must not assume the player left.

signal deactivated
signal activated

## The last notification wins, so a missing focus event after a resume never leaves the app inactive.
var is_active: bool = true


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			_set_active(false)
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			_set_active(true)


func _set_active(value: bool) -> void:
	if value == is_active:
		return
	is_active = value
	if is_active:
		activated.emit()
	else:
		deactivated.emit()
