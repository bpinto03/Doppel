extends GutTest

const HOME_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/home_screen.tscn")
const SHOP_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/shop_screen.tscn")
const GAME_SCREEN_SCENE: PackedScene = preload("res://scenes/game/game_screen.tscn")
const BALANCING_CONFIG: BalancingConfig = preload("res://data/balancing.tres")
const TEST_SAVE_PATH: String = "user://test_coin_counter_save.cfg"
const STARTING_COINS: int = 42
const SEED: int = 1234
## The first compact amount, the widest one below a million, and one in millions.
const LARGE_BALANCES: Array[int] = [100000, 999999, 12345678]
const GAME_OVER_REWARD: int = 25

var _save := SaveFixture.new(TEST_SAVE_PATH)
var _base_size := Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))


func before_each() -> void:
	_save.use_test_save()
	Settings.is_music_enabled = false
	Settings.is_sound_enabled = false


func after_each() -> void:
	AudioManager.stop_music()
	_save.restore_player_save()
	AudioManager.apply_settings()
	I18n.apply_language()


func test_counter_shows_the_balance() -> void:
	CoinWallet.add_coins(STARTING_COINS)

	var home: HomeScreen = await _add_screen(HOME_SCREEN_SCENE)

	assert_eq(_get_counter(home).get_shown_text(), str(STARTING_COINS))


func test_counter_follows_the_balance() -> void:
	var home: HomeScreen = await _add_screen(HOME_SCREEN_SCENE)
	var counter: CoinCounter = _get_counter(home)

	CoinWallet.add_coins(STARTING_COINS)
	assert_eq(counter.get_shown_text(), str(STARTING_COINS))
	CoinWallet.try_spend(2)
	assert_eq(counter.get_shown_text(), str(STARTING_COINS - 2))


func test_large_balances_show_compact_and_follow_the_language() -> void:
	CoinWallet.add_coins(12500)
	var home: HomeScreen = await _add_screen(HOME_SCREEN_SCENE)

	TranslationServer.set_locale("fr")
	assert_eq(_get_counter(home).get_shown_text(), "12,5k")
	TranslationServer.set_locale("en")
	assert_eq(_get_counter(home).get_shown_text(), "12.5k")


## The real screens apply their theme after the counter is ready: the reserved width must follow that theme.
func test_large_balances_stay_inside_the_pill_on_every_screen_language_and_theme() -> void:
	for balance: int in LARGE_BALANCES:
		_set_balance(balance)
		for theme_id: String in ["paper", "night"]:
			Settings.palette_name = theme_id
			for language: String in I18n.SUPPORTED_LANGUAGES:
				TranslationServer.set_locale(language)
				var screens: Array[Control] = await _add_every_screen_with_a_counter()
				for screen: Control in screens:
					_assert_text_inside_pill(_get_counter(screen), "%d, %s, %s, %s" % [balance, theme_id, language, screen.get_script().get_global_name()])
					screen.queue_free()


func test_showing_a_compact_amount_keeps_the_exact_balance() -> void:
	_set_balance(LARGE_BALANCES[2])

	await _add_screen(HOME_SCREEN_SCENE)

	assert_eq(CoinWallet.get_coins(), LARGE_BALANCES[2])
	assert_eq(SaveManager.get_value(CoinWallet.SECTION, CoinWallet.COINS_KEY, 0), LARGE_BALANCES[2])


func _add_every_screen_with_a_counter() -> Array[Control]:
	var home: Control = await _add_screen(HOME_SCREEN_SCENE)
	var shop: Control = await _add_screen(SHOP_SCREEN_SCENE)
	var game: GameScreen = await _add_screen(GAME_SCREEN_SCENE)
	var session := GameSession.new(BALANCING_CONFIG, BalancingFixture.create_seeded_rng(SEED))
	game.start_game(session, 0)
	var game_over_panel: GameOverPanel = game.get_node("%GameOverPanel")
	game_over_panel.show_summary(GameOverSummary.new(session, 0, 0), CoinRewardResult.new(GAME_OVER_REWARD, CoinWallet.get_coins()))
	await wait_seconds(GameOverPanel.EFFECTS_CONFIG.appear_duration)
	await wait_process_frames(2)
	return [home, shop, game]


func _assert_text_inside_pill(counter: CoinCounter, context: String) -> void:
	var value: Label = counter.get_node("%Value")
	var text_width: float = value.get_theme_font(&"font").get_string_size(value.text, HORIZONTAL_ALIGNMENT_LEFT, -1, value.get_theme_font_size(&"font_size")).x
	assert_lte(text_width, value.size.x, "Text wider than its label: %s (%s)" % [value.text, context])
	assert_true(counter.get_global_rect().encloses(value.get_global_rect()), "Label outside the pill: %s" % context)


func _add_screen(scene: PackedScene) -> Control:
	var screen: Control = scene.instantiate()
	add_child_autofree(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	screen.size = _base_size
	await wait_process_frames(2)
	return screen


## The game screen holds its counter in the game over panel.
func _get_counter(screen: Control) -> CoinCounter:
	if screen is GameScreen:
		return screen.get_node("%GameOverPanel").get_node("%CoinCounter")
	return screen.get_node("%CoinCounter")


## Sets the saved balance and tells the counters, as CoinWallet does.
func _set_balance(coins: int) -> void:
	SaveManager.set_value(CoinWallet.SECTION, CoinWallet.COINS_KEY, coins)
	WalletEvents.coins_changed.emit(coins)
