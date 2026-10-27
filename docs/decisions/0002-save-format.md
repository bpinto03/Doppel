# 0002 — Save format

**Status:** accepted (2026-10-27)

## Context

The game saves locally in `user://`: record now, then settings, current game, coins, themes, purchases and daily challenge. The format must be migratable, and a kill during a write must not lose the save.

## Decision

- One `ConfigFile` at `user://save.cfg`, one section per area (`record`, `settings`, …). ConfigFile keeps Godot types (an `int` stays an `int`, unlike JSON).
- `[meta] version` holds `SaveManager.SAVE_VERSION`. When the layout changes, the version is bumped and `SaveManager.load_save()` migrates older saves step by step.
  - Version 2 writes the default theme (`settings/palette_name = "paper"`) into version 1 saves.
- Every change is written at once, to `save.cfg.tmp` first, then renamed over `save.cfg`.
- A missing or unreadable save starts empty.

## Consequences

- Callers read with a default value, so a new key needs no migration.
- Values are not encrypted: editing the record or coins locally is accepted.
