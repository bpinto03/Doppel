extends GutTest

const SHOP_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/shop_screen.tscn")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const MAIN_SCRIPT: GDScript = preload("res://scripts/main.gd")
const BASE_THEME: Theme = preload("res://assets/themes/base_theme.tres")
const TEST_RING_WIDTH: int = 16
const DRAG_STEP_COUNT: int = 8
const DRAG_STEP_DISTANCE: float = 30.0
const TEST_SAVE_PATH: String = "user://test_shop_screen_save.cfg"
const PAID_THEME_ID: StringName = &"test_paid"
const PAID_THEME_PRICE: int = 500
const LARGEST_SHOWN_BALANCE: int = 999999
const LARGEST_SHOWN_PRICE: int = 99999

var _save := SaveFixture.new(TEST_SAVE_PATH)
var _viewport_width: float = ProjectSettings.get_setting("display/window/size/viewport_width")


func before_each() -> void:
	_save.use_test_save()
	Settings.is_music_enabled = false
	Settings.is_sound_enabled = false


func after_each() -> void:
	AudioManager.stop_music()
	_save.restore_player_save()
	AudioManager.apply_settings()
	I18n.apply_language()


func test_one_card_per_theme_in_catalog_order() -> void:
	var shop: ShopScreen = _add_shop()

	var ids: Array[StringName] = []
	for card: ThemeCard in shop.get_cards():
		ids.append(card.entry.id)

	assert_eq(ids, [&"paper", &"night", &"neon", &"wood", PAID_THEME_ID])


func test_cards_show_equipped_owned_and_for_sale() -> void:
	CoinWallet.add_coins(PAID_THEME_PRICE)
	var shop: ShopScreen = _add_shop()

	assert_eq(shop.get_card(&"paper").get_state(), ThemeCard.State.EQUIPPED)
	assert_false(shop.get_card(&"paper").is_action_enabled())
	assert_eq(shop.get_card(&"night").get_state(), ThemeCard.State.OWNED)
	assert_true(shop.get_card(&"night").is_action_enabled())
	assert_false(shop.get_card(&"night").is_price_shown())
	assert_eq(shop.get_card(PAID_THEME_ID).get_state(), ThemeCard.State.FOR_SALE)
	assert_true(shop.get_card(PAID_THEME_ID).is_action_enabled())
	assert_true(shop.get_card(PAID_THEME_ID).is_price_shown())
	_assert_action(shop.get_card(&"paper"), "UI_THEME_EQUIPPED", UiThemeBuilder.SHOP_EQUIP_BUTTON_TYPE)
	_assert_action(shop.get_card(&"night"), "UI_THEME_EQUIP", UiThemeBuilder.SHOP_EQUIP_BUTTON_TYPE)
	_assert_action(shop.get_card(PAID_THEME_ID), "UI_THEME_BUY", UiThemeBuilder.SHOP_BUY_BUTTON_TYPE)


func test_only_the_equipped_card_has_the_check_badge_and_the_accent_border() -> void:
	var shop: ShopScreen = _add_shop()

	for card: ThemeCard in shop.get_cards():
		var is_equipped: bool = card.entry.id == &"paper"
		var expected_variation: StringName = UiThemeBuilder.SHOP_CARD_EQUIPPED_TYPE if is_equipped else UiThemeBuilder.SHOP_CARD_TYPE
		assert_eq(card.is_check_badge_shown(), is_equipped, String(card.entry.id))
		assert_eq(card.theme_type_variation, expected_variation, String(card.entry.id))


func test_every_state_gives_the_same_card_height() -> void:
	CoinWallet.add_coins(PAID_THEME_PRICE)
	var shop: ShopScreen = _add_shop()
	await wait_process_frames(1)

	var heights: Array[float] = []
	for card: ThemeCard in shop.get_cards():
		heights.append(card.size.y)

	assert_eq(heights.min(), heights.max(), str(heights))


func test_a_theme_too_expensive_shows_its_price_with_buy_disabled() -> void:
	CoinWallet.add_coins(PAID_THEME_PRICE - 1)
	var shop: ShopScreen = _add_shop()

	var card: ThemeCard = shop.get_card(PAID_THEME_ID)
	assert_eq(card.get_state(), ThemeCard.State.FOR_SALE)
	assert_true(card.is_price_shown())
	assert_false(card.is_action_enabled())
	_assert_action(card, "UI_THEME_BUY", UiThemeBuilder.SHOP_BUY_BUTTON_TYPE)


func test_buy_follows_the_balance() -> void:
	CoinWallet.add_coins(PAID_THEME_PRICE - 1)
	var shop: ShopScreen = _add_shop()
	var card: ThemeCard = shop.get_card(PAID_THEME_ID)

	CoinWallet.add_coins(1)
	assert_true(card.is_action_enabled())
	CoinWallet.try_spend(1)
	assert_false(card.is_action_enabled())


func test_buying_updates_the_card_and_the_counter_without_equipping() -> void:
	CoinWallet.add_coins(PAID_THEME_PRICE + 7)
	var shop: ShopScreen = _add_shop()
	var card: ThemeCard = shop.get_card(PAID_THEME_ID)

	card.action_pressed.emit()

	assert_eq(card.get_state(), ThemeCard.State.OWNED)
	assert_eq(CoinWallet.get_coins(), 7)
	assert_eq((shop.get_node("%CoinCounter") as CoinCounter).get_shown_text(), "7")
	assert_eq(Settings.palette_name, "paper")


func test_equipping_recolors_the_screen_and_moves_the_equipped_card() -> void:
	var shop: ShopScreen = _add_shop()

	shop.get_card(&"night").action_pressed.emit()

	assert_eq(Settings.palette_name, "night")
	assert_eq((shop.get_node("%Background") as ColorRect).color, Settings.THEME_CATALOG.find_entry(&"night").palette.background)
	assert_eq(shop.get_card(&"night").get_state(), ThemeCard.State.EQUIPPED)
	assert_eq(shop.get_card(&"paper").get_state(), ThemeCard.State.OWNED)


func test_card_actions_play_the_click() -> void:
	var shop: ShopScreen = _add_shop()

	shop.get_card(&"night").action_pressed.emit()

	assert_true(_is_playing(ShopScreen.AUDIO_CONFIG.ui_click.stream))


func test_back_asks_to_leave() -> void:
	var shop: ShopScreen = _add_shop()
	watch_signals(shop)

	(shop.get_node("%BackButton") as Button).pressed.emit()

	assert_signal_emitted(shop, "back_requested")


## Paper is active, so the Night preview proves the frame and tiles ignore the active palette.
func test_each_preview_draws_with_its_own_theme() -> void:
	var shop: ShopScreen = _add_shop()

	for card: ThemeCard in shop.get_cards():
		var preview: ThemePreview = card.get_node("%Preview")
		var palette: ThemePalette = card.entry.palette
		assert_eq(preview.get_tile_painter().palette, palette, String(card.entry.id))
		assert_eq(preview.get_frame_colors(), [palette.background, palette.frame_fill, palette.frame_border] as Array[Color], String(card.entry.id))
	var night_frame: Array[Color] = (shop.get_card(&"night").get_node("%Preview") as ThemePreview).get_frame_colors()
	assert_ne(night_frame[0], Settings.get_palette().background)


func test_no_ring_around_previews_by_default() -> void:
	var shop: ShopScreen = _add_shop()

	for card: ThemeCard in shop.get_cards():
		assert_eq((card.get_node("%Preview") as ThemePreview).get_ring().border_width_left, 0, String(card.entry.id))


## The ring belongs to the shop, not to the previewed theme: every preview takes the one of the active palette.
func test_every_preview_takes_the_ring_of_the_active_theme() -> void:
	var palette: ThemePalette = Settings.get_palette().duplicate()
	palette.shop_preview_ring = Color.SADDLE_BROWN
	palette.shop_preview_ring_width = TEST_RING_WIDTH
	var shop: ShopScreen = _add_shop()

	shop.theme = UiThemeBuilder.build(palette, BASE_THEME)

	for card: ThemeCard in shop.get_cards():
		var ring: StyleBoxFlat = (card.get_node("%Preview") as ThemePreview).get_ring()
		assert_eq(ring.border_width_left, TEST_RING_WIDTH, String(card.entry.id))
		assert_eq(ring.border_color, Color.SADDLE_BROWN, String(card.entry.id))
		assert_false(ring.draw_center, String(card.entry.id))


func test_the_wheel_over_a_card_scrolls_the_list() -> void:
	var shop: ShopScreen = await _add_shop_in_own_viewport()
	var start: Vector2 = _get_center(shop, "%DescriptionLabel")

	_push_wheel_down(shop.get_viewport(), start)
	await wait_process_frames(2)

	assert_gt(_get_scroll(shop).scroll_vertical, 0)


## Four cards overflow the base height, so a drag must scroll wherever it starts on a card, its button included.
func test_dragging_a_card_scrolls_the_list_without_pressing_its_button() -> void:
	for node_path: String in ["%DescriptionLabel", "%ActionButton"]:
		var shop: ShopScreen = await _add_shop_in_own_viewport()
		watch_signals(shop.get_card(&"night"))

		await _drag_up(shop.get_viewport(), _get_center(shop, node_path))

		assert_gt(_get_scroll(shop).scroll_vertical, 0, node_path)
		assert_signal_not_emitted(shop.get_card(&"night"), "action_pressed", node_path)


func test_tapping_a_card_button_still_presses_it() -> void:
	var shop: ShopScreen = await _add_shop_in_own_viewport()
	var center: Vector2 = _get_center(shop, "%ActionButton")
	watch_signals(shop.get_card(&"night"))

	_push_left_button(shop.get_viewport(), center, true)
	_push_left_button(shop.get_viewport(), center, false)
	await wait_process_frames(1)

	assert_signal_emitted(shop.get_card(&"night"), "action_pressed")


## The longest name and description, a five digit price and a six digit balance stay within the base width:
## the name and price in full, the description on two lines at most.
func test_content_fits_the_base_width_in_every_language_and_theme() -> void:
	CoinWallet.add_coins(LARGEST_SHOWN_BALANCE)
	for theme_id: StringName in [&"paper", &"night"]:
		Settings.palette_name = String(theme_id)
		for language: String in I18n.SUPPORTED_LANGUAGES:
			TranslationServer.set_locale(language)
			var shop: ShopScreen = _add_shop(_create_catalog_with_longest_texts())
			shop.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			shop.size = Vector2(_viewport_width, ProjectSettings.get_setting("display/window/size/viewport_height"))
			await wait_process_frames(2)

			var context: String = "%s in %s" % [theme_id, language]
			assert_lte((shop.get_node("Margin") as Control).get_combined_minimum_size().x, _viewport_width, context)
			assert_lte((shop.get_node("CornerMargin") as Control).get_combined_minimum_size().x, _viewport_width, context)
			for card: ThemeCard in shop.get_cards():
				var card_context: String = "%s, %s" % [card.entry.id, context]
				assert_lte(card.get_description_line_count(), UiThemeBuilder.SHOP_DESCRIPTION_MAX_LINES, card_context)
				_assert_text_fits(card.get_node("%NameLabel"), card_context)
			_assert_text_fits(shop.get_card(PAID_THEME_ID).get_node("%PriceLabel"), context)


func test_shop_opens_from_home_and_back_returns_home() -> void:
	var main: Node = _start_main(false)

	(main.get_current_screen() as HomeScreen).shop_requested.emit()
	assert_true(main.get_current_screen() is ShopScreen)
	main.go_back()

	assert_true(main.get_current_screen() is HomeScreen)


func test_debug_starting_coins_only_in_a_debug_build_without_a_saved_balance() -> void:
	assert_true(MAIN_SCRIPT.should_grant_debug_starting_coins(true, false))
	assert_false(MAIN_SCRIPT.should_grant_debug_starting_coins(true, true))
	assert_false(MAIN_SCRIPT.should_grant_debug_starting_coins(false, false))
	assert_false(MAIN_SCRIPT.should_grant_debug_starting_coins(false, true))


func test_a_release_build_never_grants_the_debug_starting_coins() -> void:
	_start_main(false)

	assert_eq(CoinWallet.get_coins(), 0)
	assert_false(SaveManager.get_section(CoinWallet.SECTION).has(CoinWallet.COINS_KEY))


func test_a_debug_build_grants_the_starting_coins_once() -> void:
	_start_main(true)
	assert_eq(CoinWallet.get_coins(), MAIN_SCRIPT.DEBUG_STARTING_COINS)
	CoinWallet.try_spend(PAID_THEME_PRICE)

	_start_main(true)

	assert_eq(CoinWallet.get_coins(), MAIN_SCRIPT.DEBUG_STARTING_COINS - PAID_THEME_PRICE)


func _add_shop(catalog: ThemeCatalog = _create_catalog_with_paid_theme()) -> ShopScreen:
	var shop: ShopScreen = SHOP_SCREEN_SCENE.instantiate()
	shop.catalog = catalog
	add_child_autofree(shop)
	return shop


func _start_main(is_debug_build: bool) -> Node:
	var main: Node = MAIN_SCENE.instantiate()
	main.is_debug_build = is_debug_build
	add_child_autofree(main)
	return main


## The shipped themes plus a paid one, so the shop is tested without a paid theme in the shipped data.
func _create_catalog_with_paid_theme() -> ThemeCatalog:
	var catalog: ThemeCatalog = Settings.THEME_CATALOG.duplicate()
	var entries: Array[ThemeEntry] = Settings.THEME_CATALOG.get_entries().duplicate()
	entries.append(_create_paid_entry("THEME_NAME_NIGHT"))
	catalog.entries = entries
	return catalog


## The paid entry takes the longest shipped name and description in the current language, and the largest price.
func _create_catalog_with_longest_texts() -> ThemeCatalog:
	var catalog: ThemeCatalog = _create_catalog_with_paid_theme()
	var paid_entry: ThemeEntry = catalog.entries[catalog.entries.size() - 1]
	for entry: ThemeEntry in Settings.THEME_CATALOG.get_entries():
		if tr(entry.display_name_key).length() > tr(paid_entry.display_name_key).length():
			paid_entry.display_name_key = entry.display_name_key
		if tr(entry.description_key).length() > tr(paid_entry.description_key).length():
			paid_entry.description_key = entry.description_key
	paid_entry.price = LARGEST_SHOWN_PRICE
	return catalog


func _assert_action(card: ThemeCard, text: String, variation: StringName) -> void:
	assert_eq(card.get_action_text(), text, String(card.entry.id))
	assert_eq(card.get_action_variation(), variation, String(card.entry.id))


func _assert_text_fits(label: Label, context: String) -> void:
	var font: Font = label.get_theme_font(&"font")
	var text_width: float = font.get_string_size(tr(label.text), HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size(&"font_size")).x
	assert_lte(text_width, label.size.x, "%s: %s" % [label.name, context])


func _create_paid_entry(name_key: String) -> ThemeEntry:
	var paid_entry := ThemeEntry.new()
	paid_entry.id = PAID_THEME_ID
	paid_entry.palette = Settings.THEME_CATALOG.find_entry(&"night").palette
	paid_entry.price = PAID_THEME_PRICE
	paid_entry.display_name_key = name_key
	paid_entry.description_key = "THEME_DESC_NIGHT"
	return paid_entry


func _is_playing(stream: AudioStream) -> bool:
	for player: Node in AudioManager.get_children():
		if player is AudioStreamPlayer and (player as AudioStreamPlayer).stream == stream and (player as AudioStreamPlayer).playing:
			return true
	return false


func _push_wheel_down(viewport: Viewport, position: Vector2) -> void:
	for is_pressed: bool in [true, false]:
		var wheel := InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
		wheel.pressed = is_pressed
		wheel.position = position
		wheel.global_position = position
		viewport.push_input(wheel)


## ScrollContainer drags only with a touchscreen, as on a phone, where touches also arrive as mouse events.
func _drag_up(viewport: Viewport, start: Vector2) -> void:
	var was_emulating_touch: bool = Input.emulate_touch_from_mouse
	Input.emulate_touch_from_mouse = true
	_push_left_button(viewport, start, true)
	for step: int in range(1, DRAG_STEP_COUNT + 1):
		var motion := InputEventMouseMotion.new()
		motion.position = start - Vector2(0, DRAG_STEP_DISTANCE * step)
		motion.global_position = motion.position
		motion.relative = Vector2(0, -DRAG_STEP_DISTANCE)
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		viewport.push_input(motion)
		await wait_process_frames(1)
	_push_left_button(viewport, start - Vector2(0, DRAG_STEP_DISTANCE * DRAG_STEP_COUNT), false)
	await wait_process_frames(1)
	Input.emulate_touch_from_mouse = was_emulating_touch


func _push_left_button(viewport: Viewport, position: Vector2, is_pressed: bool) -> void:
	var button := InputEventMouseButton.new()
	button.button_index = MOUSE_BUTTON_LEFT
	button.pressed = is_pressed
	button.position = position
	button.global_position = position
	viewport.push_input(button)


## The test runner's own interface covers the root viewport and would take the input.
func _add_shop_in_own_viewport() -> ShopScreen:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(int(_viewport_width), ProjectSettings.get_setting("display/window/size/viewport_height"))
	add_child_autofree(viewport)
	var shop: ShopScreen = SHOP_SCREEN_SCENE.instantiate()
	shop.catalog = _create_catalog_with_paid_theme()
	viewport.add_child(shop)
	await wait_process_frames(2)
	return shop


func _get_scroll(shop: ShopScreen) -> ScrollContainer:
	return shop.get_node("Margin/Layout/Scroll")


func _get_center(shop: ShopScreen, night_card_node_path: String) -> Vector2:
	return (shop.get_card(&"night").get_node(night_card_node_path) as Control).get_global_rect().get_center()
