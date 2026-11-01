# 0008 — Themes and purchase

**Status:** accepted (2026-11-01)

## Context

The shop sells themes for coins, on top of the free Paper and Night. Until now the themes were a dictionary in `Settings`. Bought themes and the equipped theme are saved, so their ids outlive any change to the theme list, and a purchase changes two save values: the coins and the owned themes.

## Decision

- Every theme is a `ThemeEntry` of `data/theme_catalog.tres` (`ThemeCatalog`): `id`, `palette`, `price`, `display_name_key`. A new theme is a data change: a palette and an entry.
- Ids are snake_case and stable: they are saved, so an id is never renamed.
- The price lives in the catalog. A theme at price 0 is always owned and never written; bought ids go to the `themes` section, key `owned`. No migration: a missing section means no bought theme.
- `ThemeShop.try_buy()` spends the coins with `CoinWallet.try_spend()`, then adds the id to `owned`, with no `flush()` between them: `SaveManager` writes both in its end-of-frame write ([0005](0005-save-writing.md)). Spending first means a short balance stops the purchase before anything changes.
- The equipped theme stays `settings/palette_name`. `ThemeShop.resolve_equipped_id()` is the only place that reads it as a theme: an unknown or unowned id shows the catalog default, `paper`, without error and without rewriting the save.
- `equip()` only writes `Settings.palette_name`; `palette_changed` stays the only way screens recolor. Buying does not equip.

## Consequences

- A kill before the write keeps the coins and gives no theme; a kill during it leaves the old or the new save, never half of it.
- Removing a theme from the catalog, or a save from another build, falls back to Paper instead of failing.
- `rules_version` is unchanged: themes never change a game.
- Palette tests go through the shipped catalog, so a new theme is checked as soon as it is added.
