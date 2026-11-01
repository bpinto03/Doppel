extends GutTest

const HOME_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/home_screen.tscn")
const TEST_SAVE_PATH: String = "user://test_theme_shop_save.cfg"
const PAID_THEME_ID: StringName = &"test_paid"
const PAID_THEME_PRICE: int = 500
const UNKNOWN_THEME_ID: StringName = &"unknown_theme"

var _save := SaveFixture.new(TEST_SAVE_PATH)
var _catalog: ThemeCatalog
var _shop: ThemeShop


func before_each() -> void:
	_save.use_test_save()
	Settings.is_music_enabled = false
	Settings.is_sound_enabled = false
	_catalog = _create_catalog_with_paid_theme()
	_shop = ThemeShop.new(_catalog)


func after_each() -> void:
	AudioManager.stop_music()
	_save.restore_player_save()
	AudioManager.apply_settings()


func test_shipped_catalog_holds_paper_and_night_for_free() -> void:
	var catalog: ThemeCatalog = Settings.THEME_CATALOG

	assert_eq(catalog.get_entries().size(), 2)
	assert_eq(catalog.get_default_id(), &"paper")
	assert_eq(catalog.find_entry(&"paper").price, 0)
	assert_eq(catalog.find_entry(&"night").price, 0)
	assert_null(catalog.find_entry(UNKNOWN_THEME_ID))


func test_shipped_catalog_ids_are_unique_and_named() -> void:
	var ids: Array[StringName] = []
	for entry: ThemeEntry in Settings.THEME_CATALOG.get_entries():
		assert_false(ids.has(entry.id), "Duplicate id %s" % entry.id)
		assert_not_null(entry.palette, String(entry.id))
		assert_ne(tr(entry.display_name_key), entry.display_name_key, String(entry.id))
		ids.append(entry.id)


func test_every_shipped_name_and_description_is_translated() -> void:
	for language: String in I18n.SUPPORTED_LANGUAGES:
		var translation: Translation = TranslationServer.get_translation_object(language)
		for entry: ThemeEntry in Settings.THEME_CATALOG.get_entries():
			for key: String in [entry.display_name_key, entry.description_key]:
				assert_ne(String(translation.get_message(key)), "", "%s %s" % [key, language])


func test_shipped_default_theme_is_free() -> void:
	assert_eq(Settings.THEME_CATALOG.find_entry(Settings.THEME_CATALOG.get_default_id()).price, 0)


func test_free_themes_are_owned_and_a_paid_one_is_not_at_first() -> void:
	assert_true(_shop.is_owned(&"paper"))
	assert_true(_shop.is_owned(&"night"))
	assert_false(_shop.is_owned(PAID_THEME_ID))
	assert_false(_shop.is_owned(UNKNOWN_THEME_ID))


func test_buying_with_enough_coins_charges_the_price_and_survives_a_reload() -> void:
	CoinWallet.add_coins(PAID_THEME_PRICE + 1)

	assert_true(_shop.try_buy(PAID_THEME_ID))
	SaveManager.flush()
	SaveManager.load_save()

	assert_eq(CoinWallet.get_coins(), 1)
	assert_true(_shop.is_owned(PAID_THEME_ID))


func test_buying_with_the_exact_price_empties_the_wallet() -> void:
	CoinWallet.add_coins(PAID_THEME_PRICE)

	assert_true(_shop.try_buy(PAID_THEME_ID))
	assert_eq(CoinWallet.get_coins(), 0)
	assert_true(_shop.is_owned(PAID_THEME_ID))


func test_buying_without_enough_coins_changes_nothing() -> void:
	CoinWallet.add_coins(PAID_THEME_PRICE - 1)

	assert_false(_shop.try_buy(PAID_THEME_ID))
	assert_eq(CoinWallet.get_coins(), PAID_THEME_PRICE - 1)
	assert_false(_shop.is_owned(PAID_THEME_ID))


func test_buying_an_owned_theme_charges_nothing() -> void:
	CoinWallet.add_coins(PAID_THEME_PRICE * 2)
	_shop.try_buy(PAID_THEME_ID)

	assert_false(_shop.try_buy(PAID_THEME_ID))
	assert_eq(CoinWallet.get_coins(), PAID_THEME_PRICE)


func test_free_and_unknown_themes_cannot_be_bought() -> void:
	CoinWallet.add_coins(PAID_THEME_PRICE)

	assert_false(_shop.try_buy(&"night"))
	assert_false(_shop.try_buy(UNKNOWN_THEME_ID))
	assert_eq(CoinWallet.get_coins(), PAID_THEME_PRICE)
	assert_true(SaveManager.get_section(ThemeShop.SECTION).is_empty())


## Both changes wait for the same end-of-frame write: a kill before it loses neither the coins nor gives the theme.
func test_a_kill_before_the_write_keeps_the_coins_and_no_theme() -> void:
	CoinWallet.add_coins(PAID_THEME_PRICE)
	SaveManager.flush()

	_shop.try_buy(PAID_THEME_ID)
	SaveManager.load_save()

	assert_eq(CoinWallet.get_coins(), PAID_THEME_PRICE)
	assert_false(_shop.is_owned(PAID_THEME_ID))


func test_buying_does_not_equip() -> void:
	CoinWallet.add_coins(PAID_THEME_PRICE)

	_shop.try_buy(PAID_THEME_ID)

	assert_eq(Settings.palette_name, "paper")


func test_equipping_an_owned_theme_saves_it() -> void:
	assert_true(_shop.equip(&"night"))
	assert_eq(Settings.palette_name, "night")


func test_equipping_a_theme_not_owned_or_unknown_is_refused() -> void:
	assert_false(_shop.equip(PAID_THEME_ID))
	assert_false(_shop.equip(UNKNOWN_THEME_ID))
	assert_eq(Settings.palette_name, "paper")


func test_unknown_or_not_owned_saved_theme_resolves_to_the_default() -> void:
	assert_eq(_shop.resolve_equipped_id(UNKNOWN_THEME_ID), &"paper")
	assert_eq(_shop.resolve_equipped_id(PAID_THEME_ID), &"paper")
	assert_eq(_shop.resolve_equipped_id(&"night"), &"night")


func test_unknown_saved_theme_shows_paper() -> void:
	SaveManager.set_value(Settings.SECTION, Settings.PALETTE_NAME_KEY, String(UNKNOWN_THEME_ID))

	assert_eq(Settings.palette_name, "paper")
	assert_eq(Settings.get_palette(), Settings.THEME_CATALOG.find_entry(&"paper").palette)


func test_damaged_owned_list_reads_as_no_bought_theme() -> void:
	SaveManager.set_value(ThemeShop.SECTION, ThemeShop.OWNED_KEY, 12)

	assert_false(_shop.is_owned(PAID_THEME_ID))
	assert_true(_shop.is_owned(&"paper"))


func test_equipping_recolors_an_open_screen() -> void:
	var home: HomeScreen = HOME_SCREEN_SCENE.instantiate()
	add_child_autofree(home)

	ThemeShop.new(Settings.THEME_CATALOG).equip(&"night")

	assert_eq((home.get_node("%Background") as ColorRect).color, Settings.THEME_CATALOG.find_entry(&"night").palette.background)


## The shipped themes plus a paid one, so purchases are tested without a paid theme in the shipped data.
func _create_catalog_with_paid_theme() -> ThemeCatalog:
	var catalog: ThemeCatalog = Settings.THEME_CATALOG.duplicate()
	var paid_entry := ThemeEntry.new()
	paid_entry.id = PAID_THEME_ID
	paid_entry.palette = Settings.THEME_CATALOG.find_entry(&"night").palette
	paid_entry.price = PAID_THEME_PRICE
	paid_entry.display_name_key = "THEME_NAME_NIGHT"
	paid_entry.description_key = "THEME_DESC_NIGHT"
	var entries: Array[ThemeEntry] = Settings.THEME_CATALOG.get_entries().duplicate()
	entries.append(paid_entry)
	catalog.entries = entries
	return catalog
