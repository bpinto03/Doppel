# Architecture

Game logic is separated from presentation. The core never touches nodes, scenes, audio, ads or files. Platform services live in autoloads.

## Modules

### `scripts/core/` — pure logic (`RefCounted` / `Resource`)

| Class | Responsibility |
|-------|----------------|
| `BalancingConfig`, `SpawnWeightTier` | Typed balancing values, loaded from `data/balancing.tres` by the presentation layer and injected into the core |
| `BoardState` | Grid of tile levels (`0` = empty), mirror columns, landing cells, gravity |
| `TileGenerator` | Weighted draw of the current and next tile from an injected `RandomNumberGenerator`; optional scripted levels are drawn first |
| `MergeResolver` | Finds merge groups, picks where each result lands, loops merge + gravity until stable |
| `MergeGroup`, `ChainResult` | Data returned by the resolver; `ChainResult.events` lists the turn's resolution events in order |
| `ResolutionEvent` and subclasses, `TileFall` | One step of a turn (see below) |
| `MergeScoring` | Tile values, chain multiplier, merge points |
| `GameSession` | One game: turn flow, reflection, distorted reflection, score, highest level, game over. Starts on an empty board, or from a given board and scripted tile sequence. `preview_placement()` tells where the tile and its reflection would land, without changing the board |

### `scripts/tutorial/` — tutorial content

Not part of the core: steps carry translation keys and highlight hints for the presentation.

| Class | Responsibility |
|-------|----------------|
| `TutorialStep` | One step: texts, initial board, scripted tiles, target column, cells and axis to highlight. Creates its `GameSession` with dedicated rules (6×6 grid, no distorted reflection) independent of `data/balancing.tres` |
| `TutorialScenarios` | The three steps: drop, merge, merge across the axis |

### `scripts/ui/` — presentation

| Script | Responsibility |
|--------|----------------|
| `game_screen.gd` | Owns the `GameSession`, forwards released columns, starts the playback of each turn, refreshes the HUD when it ends, emits `turn_playback_finished`, saves the best score through `SaveManager`, applies the active palette (colors and background image) and rebuilds it on `Settings.palette_changed`; in debug builds, shows a theme switch button and logs `DisplayServer.is_dark_mode()` |
| `board_view.gd` | Draws the board frame (`StyleBoxFlat`, palette `panel` color), the displayed board, moving tiles, merge pulses and the placement ghost, dims unplayable columns, maps a touched column to the played left column (`find_played_column`), emits `column_released` and `pressed_while_locked`. The mirror axis is a child `ColorRect`, placed when the board or the view size changes |
| `board_style.gd` | `BoardStyle`: frame padding and corner radius, cell gap, axis width, loaded from `data/board_style.tres` |
| `tutorial_panel.gd` | Shows a step's instruction, then its explanation with Next / Play; Skip at any time. Emits `next_requested`, `skip_requested` |
| `tutorial_hint_config.gd` | Tutorial highlight pulse period, loaded from `data/tutorial_hint.tres` |
| `resolution_playback.gd` | Replays a turn's resolution events with simple tweens, emits `playback_finished` |
| `resolution_playback_config.gd` | Playback durations, curves and chain intensity, loaded from `data/resolution_playback.tres` |
| `tile_swatch.gd` | Draws one tile (current, reflection, next previews) |
| `tile_painter.gd` | Draws a tile with the active palette: a rounded `StyleBoxFlat` with a darker bottom relief, and its value sized with `TileTextConfig`. Empty cells use the same shape, sunken (darker top border). `draw_tile_shape()` draws the same rounded shape, filled or outlined, for merge pulses and tutorial highlights |
| `theme_palette.gd` | `ThemePalette`: colors of one theme, for the interface, board and tiles |
| `tile_text_config.gd` | Font and size limits of tile values, loaded from `data/tile_text.tres` |
| `ui_theme_builder.gd` | Builds the interface `Theme` (label color, panels, buttons) of a palette on top of `assets/themes/base_theme.tres` |
| `safe_area_margin.gd` | `MarginContainer` whose scene margins are measured from the safe area (notch, system bars), on mobile only |

### `scripts/autoload/` — platform services

Loaded in this order; each one may use the ones above it.

| Autoload | Responsibility |
|----------|----------------|
| `SaveManager` | Versioned local save in `user://save.cfg` (see [0002](decisions/0002-save-format.md)). `get_value` / `set_value` by section and key; every change is written at once |
| `Settings` | Sound, music, vibration, language and theme (`palette_name`: `paper` or `night`), stored in the `settings` section. Emits `changed`, and `palette_changed` for the theme |
| `I18n` | Sets the locale: chosen language, else the device language if supported (en, fr), else English |
| `AudioManager` | `play_sound()` and `play_music()`, silent when the matching setting is off |

### Scenes

- `scenes/main.tscn`: entry point, hosts the game screen.
- `scenes/game/game_screen.tscn`: HUD with "?" button, previews, board, tutorial panel, restart button.
- `scenes/game/tutorial_panel.tscn`: tutorial message and buttons.

### Data and assets

- `data/balancing.tres`: every gameplay value (see [balancing.md](balancing.md)).
- `data/resolution_playback.tres`: playback durations (see [balancing.md](balancing.md)).
- `data/tutorial_hint.tres`: tutorial highlight pulse period.
- `data/palette_paper.tres`, `data/palette_night.tres`: the two default themes (see [0003](decisions/0003-art-direction.md)).
- `data/tile_text.tres`: tile value font and size limits.
- `data/board_style.tres`: board frame, cell gap and axis sizes.
- `assets/translations/ui.csv`: player-facing texts (en, fr).
- `assets/themes/base_theme.tres`: interface font (Fredoka SemiBold) and default font size; colors come from the palette.
- `assets/fonts/`: Fredoka SemiBold and Bold, with `OFL.txt`.
- `assets/backgrounds/`: one background image per theme, set in its palette (`background_image`) and shown by `game_screen.tscn` (`BackgroundImage`), scaled to cover the screen.

## Data flow of a turn

1. `BoardView` emits `column_released(column)` when a press made while input was enabled ends on a playable column pair. A touch on a right column is mapped to its mirror, so `column` is always a left column.
2. `GameScreen` checks `GameSession.can_play_column()` and calls `play_column()`.
3. `GameSession` drops the tile and its reflection in `BoardState`, then calls `MergeResolver.resolve_chain()`.
4. The resolver merges, applies gravity and repeats; it returns a `ChainResult` (chain length, points, highest level, events).
5. `GameSession` updates score, highest level and game over, then advances the `TileGenerator`.
6. `GameScreen` locks input and hands a copy of the board taken before the turn, with the events, to `ResolutionPlayback`.
7. When `playback_finished` fires, `GameScreen` unlocks input, redraws the board and HUD from the session state, and emits `turn_playback_finished`.

## Resolution events

`GameSession.play_column()` computes the whole turn at once. `ChainResult.events` records what happened, in order, so the presentation can replay it. The core has no delays or animations.

| Event | Recorded | Content |
|-------|----------|---------|
| `TilesPlacedEvent` | Always, first | Landing cell and level of the tile and of its reflection, distorted or not |
| `GroupMergedEvent` | Once per merge group | Chain link, multiplier, group cells and level, result cell and level, points, crossing the axis or not |
| `TilesFellEvent` | After the merges of a link, only if a tile moved | Chain link, one `TileFall` (from, to, level) per tile |

- Groups of the same chain link merge at the same time: their `GroupMergedEvent`s follow each other with the same `chain_link`.
- `TilesFellEvent.chain_link` is always 1 or more. A placed tile lands directly on top of its column, so gravity never runs before the first merge. The drop from the top of the board is not an event: the presentation animates it from `TilesPlacedEvent`.
- `ResolutionEvent.apply_to(board)` replays one step. Applying every event, in order, to a copy of the board taken before the turn (`BoardState.duplicate_board()`) gives the final board. Tests check this, and that the events' points add up to the score gained.

## Board layout

`BoardView` fits the board, inside its frame padding, to its width. Cells stretch vertically up to `MAX_CELL_HEIGHT_RATIO` (1.3) to fill the free height, so a board with more columns stays about as tall. When the height is the limit, cells stay square. The board is centered in `BoardView`.

## Placement ghost

While a finger is down on the board, or the mouse hovers it on PC, `BoardView` asks `GameSession.preview_placement()` for the played left column under the pointer (either half) and draws the tile and its reflection, translucent, where they will land, linked by a thin line across the axis. The ghost is hidden while input is locked (`BoardView.is_ghost_visible()`).

## Resolution playback

- `ResolutionPlayback` builds one `Tween` for the whole turn: placed tiles drop from the top row, speeding up, and squash on landing, each chain link flashes its groups, slides them onto their result cells and pops the results, later links faster and with a larger pop (`ResolutionPlaybackConfig.get_chain_intensity()`), fallen tiles slide down and squash the same way, with a short pause after each step. From link 2 on, a label shows the multiplier (`x2`, `x3` …).
- The displayed board only changes through `ResolutionEvent.apply_to()`; the presentation never applies game rules.
- A turn longer than `max_chain_duration` plays faster: the tween speed scale is raised so the whole turn fits.
- While playing, the board ignores taps and the restart button is disabled. A press on the board skips: the tween stops, the remaining events are applied, and `playback_finished` fires. Outside the tutorial this unlocks the board at once, so the same press plays the next tile on release. It fires exactly once per turn, whether the playback ends or is skipped, any number of times.
- At the end, the board view shows the session board again, which matches the replayed board.

## Tutorial flow

1. `GameScreen.start_tutorial()` runs at launch and from the "?" button. It replaces the current session with the step's `TutorialStep.create_session()`.
2. `BoardView.show_tutorial_hint()` pulses the target column, its mirror, the step's cells and the axis, and sets `restricted_column` so only the target column (or its mirror) can be played.
3. On release, `GameScreen` plays the turn like any other, through `ResolutionPlayback`. The hint is cleared.
4. On `playback_finished`, the board stays locked and `TutorialPanel` shows the explanation. Next loads the following step; after the last one, or on Skip, `start_new_game()` starts a real game.

## Tests

`tests/` holds GUT tests for the core, the tutorial scenarios, the resolution playback, board input and the tutorial flow on the game screen (`test_*.gd`) and fixtures (`BoardFixture` describes boards as text, `BalancingFixture` builds explicit configs). Tests and GUT are excluded from exports.
