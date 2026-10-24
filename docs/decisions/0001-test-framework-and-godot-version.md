# 0001 — Test framework and pinned Godot version

**Status:** accepted (2026-10-25)

## Context

The core game logic (board, merges, gravity, chains, scoring, game over, seeded generation) must be unit-tested without launching the game. CLAUDE.md asks to choose between GdUnit4 and GUT in phase 1, and to pin the Godot version for the whole project.

## Decision

- **Godot 4.7 stable** (`4.7.stable.official.5b4e0cb0f`) is pinned for the project. Renderer: Compatibility.
- **GUT 9.7.1** is the test framework, vendored in `addons/gut/` (MIT, license kept in `addons/gut/LICENSE.md`).
  - Source: tag `v9.7.1` of `github.com/bitwes/Gut`, built from the `godot_4_7` branch (released 2026-07-10). GUT 9.6.x targets Godot 4.6; 9.7.x is the line made for 4.7's stricter return type checks.
  - Chosen over GdUnit4 because it is pure GDScript, runs headless with one command, and its 4.7 support is confirmed by an official tagged release.
- Tests live in `tests/`, files prefixed `test_`. Configuration: `.gutconfig.json`.

## Consequences

- Upgrading Godot requires a new decision record and a GUT version built for the new engine version.
- `addons/gut/` and `tests/` must be excluded from Android exports.
- Tests run with: `godot --headless --path . -s addons/gut/gut_cmdln.gd`.
