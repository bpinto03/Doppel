extends Node

## Owns the navigation: one screen at a time, the home screen at launch. Handles the Android back button
## (application/config/quit_on_go_back is off) and keeps the music playing across screens.

const HOME_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/home_screen.tscn")
const GAME_SCREEN_SCENE: PackedScene = preload("res://scenes/game/game_screen.tscn")
const BALANCING_CONFIG: BalancingConfig = preload("res://data/balancing.tres")

var _current_screen: Control
## The tutorial opens the first Play of each launch; it is not remembered between launches yet (step 3.1).
var _has_shown_tutorial: bool


func _ready() -> void:
	AudioManager.start_music()
	show_home()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()


## From a game, the tutorial or the game over screen, back to the home screen; from the home screen, quits.
func go_back() -> void:
	if _current_screen is HomeScreen:
		get_tree().quit()
	else:
		show_home()


func show_home() -> void:
	var home: HomeScreen = HOME_SCREEN_SCENE.instantiate()
	_replace_screen(home)
	home.show_choices(HomeMenu.get_choices(CurrentGameStore.load_session(BALANCING_CONFIG) != null))
	home.play_requested.connect(_on_play_requested)
	home.continue_requested.connect(_on_continue_requested)


func get_current_screen() -> Control:
	return _current_screen


func _on_play_requested() -> void:
	var game: GameScreen = _show_game()
	if _has_shown_tutorial:
		game.start_new_game()
	else:
		_has_shown_tutorial = true
		game.start_tutorial()


func _on_continue_requested() -> void:
	var session: GameSession = CurrentGameStore.load_session(BALANCING_CONFIG)
	if session == null:
		show_home()
		return
	_show_game().start_game(session)


func _show_game() -> GameScreen:
	var game: GameScreen = GAME_SCREEN_SCENE.instantiate()
	_replace_screen(game)
	return game


func _replace_screen(screen: Control) -> void:
	if _current_screen != null:
		_current_screen.queue_free()
	_current_screen = screen
	add_child(screen)
