extends Node

## Owns the screens: one at a time, the home screen at launch. Applies the Android back button as ScreenNavigation
## decides (application/config/quit_on_go_back is off), and keeps the music playing across screens.

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


func go_back() -> void:
	var game := _current_screen as GameScreen
	var screen: ScreenNavigation.Screen = ScreenNavigation.Screen.GAME if game != null else ScreenNavigation.Screen.HOME
	var game_state: ScreenNavigation.GameState = game.get_navigation_state() if game != null else ScreenNavigation.GameState.PLAYING
	match ScreenNavigation.resolve_back(screen, game_state):
		ScreenNavigation.BackAction.QUIT:
			get_tree().quit()
		ScreenNavigation.BackAction.SHOW_HOME:
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
	_show_game().start_game(session, CurrentGameStore.load_best_score_before_game())


func _show_game() -> GameScreen:
	var game: GameScreen = GAME_SCREEN_SCENE.instantiate()
	_replace_screen(game)
	game.home_requested.connect(show_home)
	return game


func _replace_screen(screen: Control) -> void:
	if _current_screen != null:
		_current_screen.queue_free()
	_current_screen = screen
	add_child(screen)
