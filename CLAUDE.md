# CLAUDE.md — Doppel

Context and working rules for this project. Read this file first, then `CAHIER_DES_CHARGES.md` (product spec, French) and `STEPS.md` (roadmap, French).

## Project summary

**Doppel** is a casual mobile puzzle game for **Android**, built with **Godot 4** and **GDScript**.

The board is split by a central mirror axis. The player drops a numbered tile on the left side, and its **reflection** drops on the right side. Identical adjacent tiles merge into a higher level, and merges can chain into combos. The game ends when no column can accept the tile and its reflection.

- Solo side project, developed in spare time. Keep the scope small and the MVP shippable.
- Monetization: rewarded ads, interstitials at the end of a game, and a one-time "remove ads" purchase.
- Must be fully playable **offline**.
- Portrait only, one-handed play, short sessions (2 to 5 minutes).

Full rules, scoring, balancing hypotheses and monetization details live in `CAHIER_DES_CHARGES.md`. Do not duplicate them here.

## Language rules

- **Everything in the code is in English**: identifiers, comments, commit messages, log messages, file and folder names, scene and node names, documentation under `docs/`.
- **Player-facing text** is never hardcoded: it goes through the translation system (French and English at launch).
- Talk to the developer in **French** in conversation. `CAHIER_DES_CHARGES.md` and `STEPS.md` stay in French.

## Code style

### Cleanliness
- The code must be understandable **by reading it**. Prefer clear names and small functions over comments.
- **Do not comment what the code already says.** No banner comments, no commented-out code, no changelog comments, no "TODO" without a clear description.
- Comment only when something is genuinely non-obvious (a tricky algorithm, a workaround, a non-evident constraint). Explain **why**, not what. Comments are in English and short.
- No dead code, no unused variables, no speculative abstractions. Build what the current step needs.
- No magic numbers: gameplay values (grid size, weights, points, ad frequency) live in the `data/` balancing config or in named constants.

### Naming
Names must say exactly what the thing is or does.

| Element | Convention | Example |
|---------|------------|---------|
| Files and folders | `snake_case` | `merge_resolver.gd`, `game_over_screen.tscn` |
| Classes (`class_name`) | `PascalCase` | `MergeResolver` |
| Functions and variables | `snake_case` | `resolve_merge_chain()` |
| Constants and enum values | `UPPER_SNAKE_CASE` | `MAX_TILE_LEVEL` |
| Signals | `snake_case`, past tense | `tile_merged`, `game_over` |
| Private members | leading underscore | `_pending_merges` |
| Booleans | read as a question | `is_column_full`, `has_pending_merges` |
| Functions | start with a verb | `spawn_next_tile()`, `calculate_chain_score()` |

```gdscript
# Good
func find_merge_groups(board: BoardState) -> Array[MergeGroup]:

# Bad
func process(b, x):   # vague name, no types
func doStuff():       # not descriptive, wrong case
```

Avoid abbreviations (`idx`, `tmp`, `mgr`, `cnt`) except universally obvious ones (`i` in a trivial loop, `id`).

### GDScript specifics
- Use **static typing everywhere**: typed variables, parameters, return types, typed arrays and dictionaries.
- Prefer `class_name` for reusable classes; use `@export` for tunable scene values.
- Prefer signals for communication upward, direct calls downward. Avoid reaching into the scene tree with long node paths; expose what is needed.
- Use `await` and `Tween` for animations; never block the main thread.
- Keep functions short and single-purpose. If a function needs a comment to explain its sections, split it.

## Architecture

**Core rule: game logic is separated from presentation.**

- `scripts/core/` contains pure game logic (board, tiles, merges, gravity, chains, scoring, game over). It does **not** touch nodes, scenes, audio, ads, or save files. It extends `RefCounted` and is unit-testable without launching the game.
- Scenes and UI observe the core and animate its results. They never decide gameplay outcomes.
- Platform services (ads, purchases, saving, audio, settings, translations) are wrapped behind autoload managers so the rest of the code never depends on a specific plugin.

```
res://
  scenes/
    main.tscn
    game/                # board, tile, hud
    ui/                  # menu, shop, daily challenge, settings, game over
  scripts/
    core/                # pure logic, no engine nodes
    autoload/            # save, audio, ads, purchases, settings, localization
    ui/                  # screen and widget controllers
  assets/                # sprites, fonts, audio, themes
  data/                  # balancing and content configuration
  tests/                 # unit tests for core logic
docs/                    # project documentation (see below)
```

### Randomness
Use a seeded `RandomNumberGenerator` injected into the logic. The daily challenge derives its seed from the UTC date so every player gets the same tile sequence.

### Persistence
Local save in `user://` (record, coins, unlocked themes, settings, purchase state, current game, daily challenge). Version the save format so it can be migrated.

## Documentation

Documentation is built **incrementally**, alongside the code, never in a big batch at the end.

- `docs/README.md`: index of all docs.
- `docs/architecture.md`: modules, responsibilities, data flow. Update when structure changes.
- `docs/game_rules.md`: rules as actually implemented (source of truth once the code exists).
- `docs/balancing.md`: tunable values, what each controls, results of playtests.
- `docs/decisions/`: short decision records (`0001-title.md`) for meaningful technical choices (context, decision, consequences).
- `docs/release_checklist.md`: build, signing and store submission notes.

Rules:
- A change that alters behavior, structure, or a decision **updates the relevant doc in the same change**.
- Keep docs short, factual, and current. Delete outdated content rather than leaving it.
- Do not document what the code makes obvious.

## Workflow

- Follow `STEPS.md`. Work **one step at a time**, respect the gates, and tick checkboxes when a step is truly done.
- Before coding a feature, state in a few lines what will change and where. Prefer small, reviewable changes.
- Write or update **unit tests** for core logic (merges, gravity, chains, game over, scoring, seeded generation). Framework: GUT 9.7.1 (see `docs/decisions/0001-test-framework-and-godot-version.md`); run with `./run_tests.sh`.
- Commits follow **Conventional Commits** in English (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`), one logical change per commit.
- Do not add dependencies or plugins without discussing it first. Plugin compatibility with the chosen Godot version must be checked.

## Hard rules

- Never commit **keystores**, passwords, or signing credentials. Keep them out of the repository (`.gitignore`).
- Use **AdMob test IDs** in every non-release build. Real IDs only in the release configuration.
- Never click real ads during testing.
- The game must stay playable when ads or purchases are unavailable (offline, no fill, plugin error).
- Do not show interstitials during a game.
- Do not change the pinned Godot version without an explicit decision recorded in `docs/decisions/`.

## Definition of done (per feature)

- Behavior matches `CAHIER_DES_CHARGES.md` (or the spec is updated on purpose).
- Core logic is covered by tests.
- No leftover debug code, dead code, or unexplained magic numbers.
- Names and structure are readable without comments.
- Relevant documentation is updated.
- Tested on a real Android device when it touches input, rendering, ads or purchases.

## Current status

Tracked in `STEPS.md` (tick the boxes). Keep this section to a single line naming the current phase.

**Current phase:** Phase 2.4 audio and haptics in progress (sound effects, music and vibration done; licenses left); Gate 1 playtest pending.
