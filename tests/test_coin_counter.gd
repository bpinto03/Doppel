extends GutTest

const COIN_COUNTER_SCENE: PackedScene = preload("res://scenes/ui/coin_counter.tscn")
const HOME_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/home_screen.tscn")
const BASE_THEME: Theme = preload("res://assets/themes/base_theme.tres")
const TEST_SAVE_PATH: String = "user://test_coin_counter_save.cfg"
const STARTING_COINS: int = 42
const LARGEST_SHOWN_AMOUNT: int = 999999
const TOO_LONG_AMOUNT: int = 9999999

var _save := SaveFixture.new(TEST_SAVE_PATH)


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

	var counter: CoinCounter = _add_counter()

	assert_eq(counter.get_shown_text(), str(STARTING_COINS))


func test_counter_follows_the_balance() -> void:
	var counter: CoinCounter = _add_counter()

	CoinWallet.add_coins(STARTING_COINS)
	assert_eq(counter.get_shown_text(), str(STARTING_COINS))
	CoinWallet.try_spend(2)
	assert_eq(counter.get_shown_text(), str(STARTING_COINS - 2))


func test_six_digits_fit_in_every_language_and_more_never_widen_the_counter() -> void:
	for palette: ThemePalette in Settings.PALETTES.values():
		for language: String in I18n.SUPPORTED_LANGUAGES:
			TranslationServer.set_locale(language)
			_set_balance(LARGEST_SHOWN_AMOUNT)
			var counter: CoinCounter = _add_counter(palette)
			await wait_process_frames(1)
			var value: Label = counter.get_node("%Value")
			var text_width: float = value.get_theme_font(&"font").get_string_size(value.text, HORIZONTAL_ALIGNMENT_LEFT, -1, value.get_theme_font_size(&"font_size")).x
			var counter_width: float = counter.get_combined_minimum_size().x

			_set_balance(TOO_LONG_AMOUNT)

			var context: String = "%s in %s" % [palette.resource_path, language]
			assert_lte(text_width, value.size.x, context)
			assert_eq(counter.get_combined_minimum_size().x, counter_width, context)


func test_home_shows_the_balance() -> void:
	CoinWallet.add_coins(STARTING_COINS)
	var home: HomeScreen = HOME_SCREEN_SCENE.instantiate()
	add_child_autofree(home)

	assert_eq((home.get_node("%CoinCounter") as CoinCounter).get_shown_text(), str(STARTING_COINS))


func _add_counter(palette: ThemePalette = Settings.get_palette()) -> CoinCounter:
	var counter: CoinCounter = COIN_COUNTER_SCENE.instantiate()
	counter.theme = UiThemeBuilder.build(palette, BASE_THEME)
	add_child_autofree(counter)
	return counter


## Sets the saved balance and tells the counters, as CoinWallet does.
func _set_balance(coins: int) -> void:
	SaveManager.set_value(CoinWallet.SECTION, CoinWallet.COINS_KEY, coins)
	WalletEvents.coins_changed.emit(coins)
