# 0002 — Save format

**Status:** accepted (2026-10-27)

## Context

The game saves locally in `user://`: record now, then settings, current game, coins, themes, purchases and daily challenge. The format must be migratable, and a kill during a write must not lose the save.

## Decision

- One `ConfigFile` at `user://save.cfg`, one section per area: `record` (`best_score`, `highest_level_reached`), `settings`, `current_game` (the game in progress, see `GameSession.to_data()`). Later areas (coins, themes, purchases, daily challenge) add their own sections. ConfigFile keeps Godot types (an `int` stays an `int`, unlike JSON).
- `[meta] version` holds `SaveManager.SAVE_VERSION`. When the layout changes, the version is bumped and `SaveManager.load_save()` migrates older saves step by step.
  - Version 2 writes the default theme (`settings/palette_name = "paper"`) into version 1 saves.
- How and when the file is written, and how a damaged file is handled: see [0005](0005-save-writing.md).

## Consequences

- Callers read with a default value, so a new key or section needs no migration.
- JSON was set aside: it reads every number as a float, which would lose the 64-bit random generator state of a saved game.
- Values are not encrypted: editing the record or coins locally is accepted.
