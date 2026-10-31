# Architecture

Game logic is separated from presentation. The core never touches nodes, scenes, audio, ads or files. Platform services live in autoloads.

## Modules

### `scripts/core/` — pure logic (`RefCounted` / `Resource`)

| Class | Responsibility |
|-------|----------------|
| `BalancingConfig`, `SpawnWeightTier` | Typed balancing values, loaded from `data/balancing.tres` by the presentation layer and injected into the core |
| `BoardState` | Grid of tile levels (`0` = empty), mirror columns, landing cells, gravity. `get_levels()` and `create_from_levels()` (null for a wrong size or a level out of bounds) carry the grid as plain data; `is_settled()` checks that no tile floats |
| `TileGenerator` | Weighted draw of the current and next tile from an injected `RandomNumberGenerator`; optional scripted levels are drawn first. `to_data()` / `restore_data()` carry the current and next levels and the generator seed and state, so a restored game draws the same tiles. It is the only source of randomness in the core |
| `MergeResolver` | Finds merge groups, picks where each result lands, loops merge + gravity until stable |
| `MergeGroup`, `ChainResult` | Data returned by the resolver; `ChainResult.events` lists the turn's resolution events in order |
| `ResolutionEvent` and subclasses, `TileFall` | One step of a turn (see below) |
| `MergeScoring` | Tile values, chain multiplier, merge points |
| `GameSession` | One game: turn flow, reflection, distorted reflection, score, highest level, game over. Starts on an empty board, or from a given board and scripted tile sequence. `preview_placement()` tells where the tile and its reflection would land, without changing the board. `to_data()` turns a game into plain values (`int`, `PackedInt32Array`); `create_from_data()` rebuilds it, or returns null when the data is missing a value, has another board size or `rules_version`, holds an impossible board or levels, or describes a finished game. The core never reads or writes files |

### `scripts/tutorial/` — tutorial content

Not part of the core: steps carry translation keys and highlight hints for the presentation.

| Class | Responsibility |
|-------|----------------|
| `TutorialStep` | One step: texts, initial board, scripted tiles, target column, cells and axis to highlight. Creates its `GameSession` with dedicated rules (6×6 grid, no distorted reflection) independent of `data/balancing.tres` |
| `TutorialScenarios` | The three steps: drop, merge, merge across the axis |

### `scripts/main.gd` — navigation

`Main` (`scenes/main.tscn`) owns the navigation and shows one screen at a time, freeing the previous one:

- At launch, the home screen, never a game directly. Its choices come from `CurrentGameStore.load_session()`.
- Settings opens the settings screen from the home screen only; its Back button and the back button return home.
- Play opens the tutorial until the player finished or skipped it once (`ScreenNavigation.resolve_play()`, `PlayerProgress.has_seen_tutorial()`), then a new game. Continue resumes the saved game with `GameScreen.start_game()`, with no drop or merge animation.
- The Android back button (`NOTIFICATION_WM_GO_BACK_REQUEST`, with `application/config/quit_on_go_back` off) is resolved by `ScreenNavigation.resolve_back()` from the current screen and the game state (`GameScreen.get_navigation_state()`); `Main` applies the answer: quit from home, pause from a game in progress, resume from the pause, back to the main page of the pause from its settings, home from the tutorial, the game over screen and the settings (see [0006](decisions/0006-back-button-and-overlays.md)).
- It asks `AudioManager.start_music()` once at launch, so the music never restarts between screens.

### `scripts/save/` — saved game data

| Script | Responsibility |
|--------|----------------|
| `current_game_store.gd` | `CurrentGameStore`: the game in progress in the `current_game` save section, with the record before that game (`best_score_before_game`), so a resumed game still knows whether it beat the record. `load_session()` returns null when none is saved, and discards (with a warning) a saved game that `GameSession.create_from_data()` rejects, keeping the rest of the save. `store()` replaces the section, `erase()` removes it |
| `record_book.gd` | `RecordBook`: best score and highest tile level over every real game, in the `record` section; `submit()` only raises them |
| `player_progress.gd` | `PlayerProgress`: what the player did once and for all, in the `progress` section: `has_seen_tutorial()` (false when the key is missing), `mark_tutorial_seen()` |

### `scripts/ui/` — presentation

| Script | Responsibility |
|--------|----------------|
| `palette_screen.gd` | `PaletteScreen`: base of full screens. Applies the active palette (interface theme, background color and image) and rebuilds it on `Settings.palette_changed`; `_apply_screen_palette()` adds what a screen draws itself |
| `settings_rows.gd` | `SettingsRows`: every setting row, defined once (`scenes/ui/settings_rows.tscn`): sound, music, vibration and screen shake toggles (group `TOGGLES`), language French / English (`LANGUAGE`) and theme Paper / Night (`THEME`), each written to `Settings` at once. `shown_groups` picks the groups a screen shows |
| `settings_screen.gd` | `SettingsScreen`: every `SettingsRows` group in a scroll container, and Back (`back_requested`). Later settings (phase 4) join `SettingsRows` as a new group |
| `home_screen.gd` | `HomeScreen`: title, Play, and Continue when a game is saved, then Settings; emits `play_requested`, `continue_requested`, `settings_requested`. Lays the buttons side by side (Play left, Continue right, same width) when twice the widest button's minimum width fits, else stacks them (Continue on top), checked again on resize and language change |
| `game_over_summary.gd` | `GameOverSummary`: pure values of the game over screen (score, record, highest tile) and whether the record was just beaten, against the record before the game; a previous record of 0 is never announced as beaten |
| `game_over_panel.gd` | `GameOverPanel`: overlay over the finished game, with Play again (new game in one tap) and Menu (`menu_requested`, which `GameScreen` turns into `home_requested`). `RewardSlot` stays hidden until coins (3.2) and rewarded ads (phase 4) |
| `screen_navigation.gd` | `ScreenNavigation`: pure decisions of where the back button leads, per screen and game state (`PLAYING`, `PAUSED`, `PAUSE_SETTINGS`, `TUTORIAL`, `GAME_OVER`), and whether an inactive app pauses the game |
| `pause_panel.gd` | `PausePanel`: overlay over the paused game with two pages. Main page: Menu (keeps the game for Continue), Restart (abandons the game, which counts for the record), Settings and Resume. Settings page: the `TOGGLES` group of `SettingsRows` and Back to the main page. A new pause always opens on the main page |
| `home_menu.gd` | `HomeMenu`: pure decisions of the home screen: choices offered, their order, and whether to stack them from the buttons' real minimum widths |
| `game_screen.gd` | `GameScreen`: owns the `GameSession` (`start_new_game()`, `start_tutorial()`, or `start_game()` with a given session and the record before it), forwards released columns, saves each real turn (see Save flow), starts the playback of each turn, refreshes the HUD when it ends and shows the game over overlay when the game is over, opens and closes the pause (`open_pause()`, `close_pause()`, and `close_pause_settings()` back to its main page; the HUD pause button shows outside the tutorial), emits `turn_playback_finished` and `home_requested`, reports its state to `ScreenNavigation` (`get_navigation_state()`), redraws the tiles and combo outline with the palette |
| `board_view.gd` | Draws the board frame (`StyleBoxFlat`, palette `panel` color), the displayed board, moving tiles, merge pulses and the placement ghost, dims unplayable columns, maps a touched column to the played left column (`find_played_column`), emits `column_released`, `pressed_while_locked`, and `unplayable_column_released` on a release over a column that cannot take the pair. The mirror axis (a `ColorRect`, placed when the board or the view size changes) and board effects such as particles sit in a child effects layer |
| `merge_particles.gd` | `MergeParticles`: fixed pool of one-shot `CPUParticles2D` emitters with a generated disc texture; bursts never exceed the live particle cap |
| `board_style.gd` | `BoardStyle`: frame padding and corner radius, cell gap, axis width, loaded from `data/board_style.tres` |
| `tutorial_panel.gd` | Shows a step's instruction, then its explanation with Next / Play; Skip at any time. Emits `next_requested`, `skip_requested` |
| `tutorial_hint_config.gd` | Tutorial highlight pulse period, loaded from `data/tutorial_hint.tres` |
| `resolution_playback.gd` | Replays a turn's resolution events with simple tweens, emits `tiles_landed`, `chain_link_merged` and `playback_finished` |
| `game_feedback.gd` | `GameFeedback`: plays the sound and vibration of each game event (see Audio feedback) |
| `resolution_playback_config.gd` | Playback durations, curves and chain intensity, loaded from `data/resolution_playback.tres` |
| `combo_text.gd` | `ComboText`: combo message text, with the decimal separator of the current language |
| `tile_swatch.gd` | Draws one tile (current, reflection, next previews) |
| `tile_painter.gd` | Draws a tile with the active palette: a rounded `StyleBoxFlat` with a darker bottom relief, and its value sized with `TileTextConfig`. Empty cells use the same shape, sunken (darker top border). `draw_tile_shape()` draws the same rounded shape, filled or outlined, for merge pulses and tutorial highlights |
| `theme_palette.gd` | `ThemePalette`: colors of one theme, for the interface, board and tiles |
| `tile_text_config.gd` | Font and size limits of tile values, loaded from `data/tile_text.tres` |
| `ui_theme_builder.gd` | Builds the interface `Theme` (label color, panels, buttons, and the `ChoiceButton` variation of settings toggles and choices: outlined when off, filled when on) of a palette on top of `assets/themes/base_theme.tres` |
| `safe_area_margin.gd` | `MarginContainer` whose scene margins are measured from the safe area (notch, system bars), on mobile only |

### `tools/simulation/` — balance simulator (not exported)

Command line tool run by `./run_simulation.sh` (see [balancing.md](balancing.md#balance-simulator)). It plays games on the core only: no scene, audio, vibration or save. Excluded from the Android export (`tools/*`, `run_simulation.sh`, `simulation_results/*` in the preset's `exclude_filter`).

| File | Responsibility |
|------|----------------|
| `simulation_runner.gd` | Entry point (`extends SceneTree`): reads `--games` and `--scenarios`, plays each scenario with each strategy, prints the report, writes the CSV, and checks that the player's save is unchanged |
| `move_evaluator.gd`, `move_outcome.gd` | `MoveEvaluator`: plays a column on a copy of the board (`preview_placement()` then `MergeResolver`), without touching the session or its generator |
| `play_strategy.gd` | `PlayStrategy`: base of the `random`, `greedy` and `heuristic` strategies; ties are broken by the strategy's own seeded generator |
| `balance_simulator.gd` | `BalanceSimulator`: plays whole games, game *i* on seed `first_seed + i`, with a placement cap |
| `game_record.gd`, `simulation_stats.gd` | One game's figures, and their aggregates |
| `simulation_scenario.gd`, `scenarios.json` | `SimulationScenario`: a name and overrides applied to a copy of the balancing config |
| `simulation_report.gd` | Console table and CSV text |

### `scripts/autoload/` — platform services

Loaded in this order; each one may use the ones above it.

| Autoload | Responsibility |
|----------|----------------|
| `AppLifecycle` | Turns `NOTIFICATION_APPLICATION_PAUSED` / `FOCUS_OUT` and `RESUMED` / `FOCUS_IN` into `is_active` and the `deactivated` / `activated` signals (the last notification wins). The only place that reads these notifications (see App lifecycle) |
| `SaveManager` | Versioned local save in `user://save.cfg` (see [0002](decisions/0002-save-format.md)). `get_value` / `set_value` by section and key. Changes made in the same frame make one write at the end of the frame, and an unchanged save is not written again; `flush()` writes at once, and runs on `AppLifecycle.deactivated`. Each write goes through a checked temporary file and keeps the previous save as a backup; a missing, empty, unreadable or newer save falls back to the backup, then to an empty save (see [0005](decisions/0005-save-writing.md)) |
| `Settings` | Sound, music, vibration, screen shake, language, theme (`palette_name`: `paper` or `night`) and linear volume per audio bus (`get_bus_volume` / `set_bus_volume`, 0 to 1), stored in the `settings` section. Emits `changed`, and `palette_changed` for the theme |
| `I18n` | Sets the locale: chosen language, else the device language if supported (en, fr), else English |
| `AudioManager` | Applies the saved sound, music and volume settings to the buses at startup and on every change: a disabled sound or a volume of zero mutes its bus. `play_effect()` plays a `SoundEffect` on the `SFX` bus with a pool of reused players; a missing sound plays nothing. `start_music()` / `stop_music()` fade the looping ambient music in and out on the `Music` bus; the fades belong to the autoload. A `MusicState` decides from the music setting, the app request (`Main` asks once at launch) and the app state: play, pause while `AppLifecycle` reports the app inactive, or stop and release the stream (music disabled or no longer requested). A missing music file logs a warning and the game plays without music. |
| `HapticsManager` | The only caller of `Input.vibrate_handheld()`. `request()` keeps the strongest `HapticPulse` of the frame and sends it on the next `_process`; nothing is sent while `Settings.is_vibration_enabled` is off. A pulse closer than `min_interval_ms` to the last one sent is dropped unless it is stronger. `take_pending_pulse()` makes the decision without the device call, for tests. `pulse_sent` reports every pulse sent. On desktop, or on a phone without a vibrator, the call does nothing |

Audio buses (`default_bus_layout.tres`): `SFX` and `Music`, both sent to `Master`.

### `scripts/haptics/` — vibration data

| File | Responsibility |
|------|----------------|
| `haptic_pulse.gd` | `HapticPulse`: duration and amplitude of one vibration. `is_stronger_than()` compares the duration, felt on every phone, then the amplitude, ignored by phones that cannot set it |
| `haptics_config.gd` | `HapticsConfig` (`data/haptics_config.tres`): one pulse per event, `get_chain_link_pulse()` (climbs from `merge` on link 1 to `big_combo` at `big_combo_min_link`, then stays there) and the minimum interval |

### `scripts/audio/` — sound data

| File | Responsibility |
|------|----------------|
| `sound_effect.gd` | `SoundEffect`: a stream, its volume offset and its random pitch and volume spread |
| `audio_config.gd` | `AudioConfig` (`data/audio_config.tres`): one `SoundEffect` per event, the key and chain scale (`get_chain_semitones()`, `get_chain_pitch_scale()`, `get_game_over_pitch_scale()`, see [0004](decisions/0004-audio-key.md)), the player pool size, and the music path, volume and fades (`load_music()` returns null for a missing file) |
| `music_state.gd` | `MusicState`: pure decision of the music action (`PLAY`, `PAUSE`, `STOP`) |

Sound files live in `assets/audio/sfx/`, as short mono WAV files imported uncompressed (`compress/mode=0`: no decoding artifact, about 60 KB more in the APK for all of them; music will stay compressed): `placement.wav`, `merge.wav` (also played by `chain`), `game_over.wav`, `ui_click.wav`, `unplayable_column.wav`. A replacement with the same name needs no other change; another name or format (OGG) is set in `data/audio_config.tres`. Every sound effect file is listed in `CREDITS.md`.

The ambient music is `assets/audio/music/musical_ambiance.ogg`, one track for every theme: Ogg Vorbis (`libvorbis -q:a 4`, about 0.9 MB) imported with `loop=true` and `loop_offset=0`. Its WAV master stays outside the build in `_sources/audio/`, ignored by git and by Godot (`_sources/.gdignore`). `Main` starts the music at launch; it keeps playing across screens.

### Scenes

- `scenes/main.tscn`: entry point, `Main` (see above).
- `scenes/ui/home_screen.tscn`: title, the Play / Continue buttons and Settings.
- `scenes/ui/settings_screen.tscn`: `SettingsRows` and Back.
- `scenes/ui/settings_rows.tscn`: the setting rows, by group.
- `scenes/game/game_screen.tscn`: HUD with "?" and pause ("II") buttons, previews, board with the centered combo label, tutorial panel, pause and game over overlays.
- `scenes/game/tutorial_panel.tscn`: tutorial message and buttons.
- `scenes/game/game_over_panel.tscn`, `scenes/game/pause_panel.tscn`: game over and pause overlays of the game screen.

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
6. Outside the tutorial, `GameScreen` saves the turn (see Save flow).
7. `GameScreen` locks input and hands a copy of the board taken before the turn, with the events, to `ResolutionPlayback`.
8. When `playback_finished` fires, `GameScreen` unlocks input, redraws the board and HUD from the session state, and emits `turn_playback_finished`.

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

While a finger is down on the board, or the mouse hovers it on PC, `BoardView` asks `GameSession.preview_placement()` for the played left column under the pointer (either half) and draws the tile and its reflection where they will land, linked by a thin line across the axis. `TilePainter.draw_ghost_tile()` gives a ghost a faint fill, a solid outline and the value in the tile color, without the relief of a placed tile. The ghost fades in, pulses gently, and slides with its reflection as mirror images when the finger changes column; a new slide starts from the drawn position. The slide is visual only: a release always plays the column under the finger. Its tweens run only while the ghost is shown, and are killed when it disappears (release, locked board, unplayable column). The ghost is hidden while input is locked or on a column that cannot take the tile and its reflection (`BoardView.is_ghost_visible()`).

## Resolution playback

- `ResolutionPlayback` builds one `Tween` for the whole turn: placed tiles drop from the top row, speeding up, and squash on landing, each chain link flashes its groups, slides them onto their result cells and pops the results, later links faster and with a larger pop (`ResolutionPlaybackConfig.get_chain_intensity()`); each result tile throws a particle burst in its palette color, larger on later links, and from a configured link the board shakes (`BoardView.set_shake_offset()`, which moves the drawing and the effects layer, never the layout), unless `Settings.is_screen_shake_enabled` is off, fallen tiles slide down and squash the same way, with a short pause after each step. From link 2 on, one combo label centered on the board shows the multiplier (`x2`, `x2,5` in French), with a word from configured links, and pops at each link; it stays `combo_hold_duration` after the turn ends, and disappears at once on a skip or when the next turn starts.
- The displayed board only changes through `ResolutionEvent.apply_to()`; the presentation never applies game rules.
- A turn longer than `max_chain_duration` plays faster: the tween speed scale is raised so the whole turn fits.
- While playing, the board ignores taps and the "?" button is disabled. A press on the board skips: the tween stops, the remaining events are applied, and `playback_finished` fires. Outside the tutorial this unlocks the board at once, so the same press plays the next tile on release. It fires exactly once per turn, whether the playback ends or is skipped, any number of times.
- At the end, the board view shows the session board again, which matches the replayed board.

## Audio feedback

`GameFeedback` observes the playback and the board, like the animations, and never touches the core:

- `ResolutionPlayback.tiles_landed` (the placed pair lands): `placement`, and the `placement` pulse.
- `ResolutionPlayback.chain_link_merged(chain_link)`: one sound per link however many groups merge, `merge` on link 1, `chain` after, at `AudioConfig.get_chain_pitch_scale(chain_link)`; the `HapticsConfig.get_chain_link_pulse(chain_link)` pulse.
- `BoardView.unplayable_column_released`: `unplayable_column`.
- `game_screen` calls `play_game_over()` when a turn ends the game, played or skipped (sound and `game_over` pulse), and `play_ui_click()` on its buttons and the tutorial buttons.

Both playback signals are tween callbacks: a skip kills the tween, so the remaining steps never play their sounds late, and the next turn plays normally. `AudioManager.effect_played` reports every sound played.

## Tutorial flow

1. `GameScreen.start_tutorial()` runs on Play until the tutorial was seen, and from the "?" button. It replaces the displayed session with the step's `TutorialStep.create_session()`; the saved game in progress is left untouched.
2. `BoardView.show_tutorial_hint()` pulses the target column, its mirror, the step's cells and the axis, and sets `restricted_column` so only the target column (or its mirror) can be played.
3. On release, `GameScreen` plays the turn like any other, through `ResolutionPlayback`. The hint is cleared.
4. On `playback_finished`, the board stays locked and `TutorialPanel` shows the explanation. Next loads the following step; after the last one, or on Skip, the tutorial is marked as seen (`PlayerProgress.mark_tutorial_seen()`) and `start_new_game()` starts a real game, which replaces the saved one.

## Save flow

What is saved, in `user://save.cfg` (format: [0002](decisions/0002-save-format.md), writing: [0005](decisions/0005-save-writing.md)):

- `record`: best score and highest tile level (`RecordBook`).
- `progress`: whether the tutorial was seen (`PlayerProgress`).
- `settings`: every `Settings` value, written on each change.
- `current_game`: the game in progress, `GameSession.to_data()`, and the record before it (`CurrentGameStore`). Never the tutorial.

When:

- After each real turn, right after `play_column()` and before the playback: the session already holds the final state, so a kill during the animation keeps the turn. The record is raised, then the game is stored, or erased if the turn ended it.
- `start_new_game()` counts the saved game for the record, then replaces it with the new game. Play never clears the save by itself: with the tutorial first, the saved game stays until the tutorial starts the new game.
- Continue rebuilds the saved game with `GameSession.create_from_data()` and shows its board at once, without animation. A game the core rejects is discarded; the record and settings stay.

## App lifecycle

Background, screen lock, incoming call, notification shade and, in phase 4, full-screen ads all make the app inactive. Nothing assumes the player left: being inactive only makes the app safe to kill or to leave paused.

On `AppLifecycle.deactivated`:

- `SaveManager.flush()` writes the waiting changes; the game itself is already saved after each turn.
- `GameScreen` cancels a finger still down (`BoardView.cancel_press()`), so its release after the return plays nothing, and skips the running playback to the final state (`ResolutionPlayback.skip()`), so the app never comes back half animated. A skip plays no landing or chain sound. During a game in progress it then opens the pause (`ScreenNavigation.should_pause_when_inactive()`, see [0006](decisions/0006-back-button-and-overlays.md)).
- `AudioManager` pauses the music (`MusicState`).

In the background, Android stops the Godot main loop: tweens and processing freeze until the return. With only the focus lost (shade, call screen on top), the loop runs, but the board is idle: the playback was skipped. On `activated`, the music resumes; the game stays paused until the player resumes it.

## Tests

`tests/` holds GUT tests for the core, the tutorial scenarios, the resolution playback, board input, the tutorial flow on the game screen, saving, the home screen and the navigation (`test_*.gd`) and fixtures (`BoardFixture` describes boards as text, `BalancingFixture` builds explicit configs, `SaveFixture` points `SaveManager` at a test file and deletes it afterwards, so no test touches the player's save). Tests and GUT are excluded from exports.
