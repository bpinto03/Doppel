extends GutTest

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const GAME_SCREEN_SCENE: PackedScene = preload("res://scenes/game/game_screen.tscn")
const TEST_SAVE_PATH: String = "user://test_tutorial_progress_save.cfg"

var _save := SaveFixture.new(TEST_SAVE_PATH)


func before_each() -> void:
	_save.use_test_save()
	Settings.is_music_enabled = false
	Settings.is_sound_enabled = false


func after_each() -> void:
	AudioManager.stop_music()
	_save.restore_player_save()
	AudioManager.apply_settings()


func test_play_opens_the_tutorial_only_until_it_was_seen() -> void:
	assert_eq(ScreenNavigation.resolve_play(false), ScreenNavigation.PlayAction.TUTORIAL)
	assert_eq(ScreenNavigation.resolve_play(true), ScreenNavigation.PlayAction.NEW_GAME)


func test_a_save_without_the_key_has_not_seen_the_tutorial() -> void:
	var old_file := ConfigFile.new()
	old_file.set_value(SaveManager.META_SECTION, SaveManager.VERSION_KEY, SaveManager.SAVE_VERSION)
	old_file.set_value(RecordBook.SECTION, RecordBook.BEST_SCORE_KEY, 120)
	old_file.save(TEST_SAVE_PATH)

	SaveManager.load_save()

	assert_false(PlayerProgress.has_seen_tutorial())


func test_seen_tutorial_survives_a_reload() -> void:
	PlayerProgress.mark_tutorial_seen()
	SaveManager.flush()

	SaveManager.load_save()

	assert_true(PlayerProgress.has_seen_tutorial())


func test_finishing_the_tutorial_marks_it_seen_and_starts_a_game() -> void:
	var game: GameScreen = GAME_SCREEN_SCENE.instantiate()
	add_child_autofree(game)
	game.start_tutorial()
	var panel: TutorialPanel = game.get_node("%TutorialPanel")

	for step: int in TutorialScenarios.create_steps().size():
		assert_false(PlayerProgress.has_seen_tutorial(), "Step %d" % step)
		panel.next_requested.emit()

	assert_true(PlayerProgress.has_seen_tutorial())
	assert_false(game.is_tutorial_running())


func test_skipping_the_tutorial_marks_it_seen() -> void:
	var game: GameScreen = GAME_SCREEN_SCENE.instantiate()
	add_child_autofree(game)
	game.start_tutorial()

	(game.get_node("%TutorialPanel") as TutorialPanel).skip_requested.emit()

	assert_true(PlayerProgress.has_seen_tutorial())


func test_continue_never_opens_the_tutorial() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	add_child_autofree(main)
	var session := GameSession.new(load("res://data/balancing.tres"), BalancingFixture.create_seeded_rng(1))
	session.play_column(0)
	CurrentGameStore.store(session, 0)
	main.show_home()

	(main.get_current_screen() as HomeScreen).continue_requested.emit()

	assert_false((main.get_current_screen() as GameScreen).is_tutorial_running())
	assert_false(PlayerProgress.has_seen_tutorial())
