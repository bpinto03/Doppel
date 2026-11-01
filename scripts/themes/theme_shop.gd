class_name ThemeShop
extends RefCounted

## Owned themes, purchase and equipped theme. Bought ids live in the themes save section; free themes are never written.

const SECTION: String = "themes"
const OWNED_KEY: String = "owned"

var _catalog: ThemeCatalog


func _init(catalog: ThemeCatalog) -> void:
	_catalog = catalog


func is_owned(id: StringName) -> bool:
	var entry: ThemeEntry = _catalog.find_entry(id)
	if entry == null:
		return false
	return entry.price == 0 or _get_bought_ids().has(String(id))


## The coins and the owned list change in the same frame, so SaveManager writes them together.
func try_buy(id: StringName) -> bool:
	var entry: ThemeEntry = _catalog.find_entry(id)
	if entry == null or is_owned(id) or not CoinWallet.try_spend(entry.price):
		return false
	var bought_ids: PackedStringArray = _get_bought_ids()
	bought_ids.append(String(id))
	SaveManager.set_value(SECTION, OWNED_KEY, bought_ids)
	return true


## Settings.palette_changed recolors the screens.
func equip(id: StringName) -> bool:
	if not is_owned(id):
		return false
	Settings.palette_name = String(id)
	return true


## The theme to show for a saved id: the default one when the id is unknown or not owned.
func resolve_equipped_id(saved_id: StringName) -> StringName:
	return saved_id if is_owned(saved_id) else _catalog.get_default_id()


## A damaged value reads as no bought theme.
func _get_bought_ids() -> PackedStringArray:
	var saved: Variant = SaveManager.get_value(SECTION, OWNED_KEY, PackedStringArray())
	if saved is PackedStringArray or saved is Array:
		return PackedStringArray(saved)
	return PackedStringArray()
