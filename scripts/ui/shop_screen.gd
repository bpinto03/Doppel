class_name ShopScreen
extends PaletteScreen

## One card per theme of the catalog, in its order: buy with coins, then equip. Buying never equips.
## Laid out after docs/maquettes/*/theme_catalog_*.png: title and subtitle, the scrolling cards, then Back.
## The cards follow the balance and the equipped theme without being rebuilt.

signal back_requested

const THEME_CARD_SCENE: PackedScene = preload("res://scenes/ui/theme_card.tscn")
const AUDIO_CONFIG: AudioConfig = preload("res://data/audio_config.tres")

## Set before the screen enters the tree; tests give a catalog with a paid theme.
var catalog: ThemeCatalog = Settings.THEME_CATALOG
var _shop: ThemeShop
var _cards: Dictionary[StringName, ThemeCard] = {}

@onready var _cards_margin: MarginContainer = %CardsMargin
@onready var _card_list: VBoxContainer = %Cards
@onready var _back_button: IconActionButton = %BackButton


## The cards exist before the palette is applied, since applying it refreshes them.
func _ready() -> void:
	_back_button.custom_minimum_size = UiThemeBuilder.SHOP_BACK_BUTTON_SIZE
	_keep_room_for_card_glow()
	_shop = ThemeShop.new(catalog)
	_add_cards()
	super()
	_back_button.pressed.connect(_play_click)
	_back_button.pressed.connect(back_requested.emit)
	WalletEvents.coins_changed.connect(_on_coins_changed)


## In catalog order.
func get_cards() -> Array[ThemeCard]:
	var cards: Array[ThemeCard] = []
	for card: Node in _card_list.get_children():
		cards.append(card as ThemeCard)
	return cards


func get_card(id: StringName) -> ThemeCard:
	return _cards.get(id)


## The scroll area clips what lies outside it, the card glow included.
func _keep_room_for_card_glow() -> void:
	for side: StringName in SafeAreaMargin.MARGIN_SIDES:
		_cards_margin.add_theme_constant_override(side, UiThemeBuilder.SHOP_CARD_GLOW_SIZE)


func _add_cards() -> void:
	for entry: ThemeEntry in catalog.get_entries():
		var card: ThemeCard = THEME_CARD_SCENE.instantiate()
		card.entry = entry
		_card_list.add_child(card)
		card.action_pressed.connect(_on_card_action_pressed.bind(entry.id))
		_cards[entry.id] = card


func _apply_screen_palette(_palette: ThemePalette) -> void:
	_refresh_cards()


func _on_coins_changed(_new_total: int) -> void:
	_refresh_cards()


func _refresh_cards() -> void:
	var coins: int = CoinWallet.get_coins()
	var equipped_id := StringName(Settings.palette_name)
	for id: StringName in _cards:
		var state: ThemeCard.State = ThemeCard.resolve_state(id == equipped_id, _shop.is_owned(id))
		_cards[id].show_state(state, coins >= catalog.find_entry(id).price)


## Equipping recolors the screen through Settings.palette_changed, which refreshes the cards.
func _on_card_action_pressed(id: StringName) -> void:
	_play_click()
	match _cards[id].get_state():
		ThemeCard.State.OWNED:
			_shop.equip(id)
		ThemeCard.State.FOR_SALE:
			if _shop.try_buy(id):
				_refresh_cards()


func _play_click() -> void:
	AudioManager.play_effect(AUDIO_CONFIG.ui_click)
