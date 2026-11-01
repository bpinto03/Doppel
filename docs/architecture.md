# Architecture

Game logic is separated from presentation. The core never touches nodes, scenes, audio, ads or files. Platform services live in autoloads.

## Modules

### `scripts/core/` — pure logic (`RefCounted` / `Resource`)

| Class | Responsibility |
|-------|----------------|
| `BalancingConfig`, `SpawnWeightTier` | Typed balancing values (board, spawning, scoring, distorted reflection, coins), loaded from `data/balancing.tres` by the presentation layer and injected into the core |
| `BoardState` | Grid of tile levels (`0` = empty), mirror columns, landing cells, gravity. `get_levels()` and `create_from_levels()` (null for a wrong size or a level out of bounds) carry the grid as plain data; `is_settled()` checks that no tile floats |
| `TileGenerator` | Weighted draw of the current and next tile from an injected `RandomNumberGenerator`; optional scripted levels are drawn first. `to_data()` / `restore_data()` carry the current and next levels and the generator seed and state, so a restored game draws the same tiles. It is the only source of randomness in the core |
| `MergeResolver` | Finds merge groups, picks where each result lands, loops merge + gravity until stable |
| `MergeGroup`, `ChainResult` | Data returned by the resolver; `ChainResult.events` lists the turn's resolution events in order |
| `ResolutionEvent` and subclasses, `TileFall` | One step of a turn (see below) |
| `MergeScoring` | Tile values, chain multiplier, merge points |
| `CoinRewardResult` | Coins paid at the end of a game and the balance after them |
| `CoinReward` | Coins earned by a finished game, from its score and highest level |
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
- Themes opens the shop (`ShopScreen`) from the home screen only, never from a game; its Back button and the back button return home.
- In a debug build, `_ready()` puts `DEBUG_STARTING_COINS` (100000) in the wallet when the save has no `wallet/coins` key yet, once: a dev tool, so the shop can be tried. `should_grant_debug_starting_coins()` decides; a release build never grants them. `is_debug_build` is set from `OS.is_debug_build()`, and tests set it before `Main` enters the tree. To be removed in phase 5 (see `STEPS.md`).
- Play always starts a new game. Tutorial opens the tutorial, which ends back on the home screen (last step or Skip), the saved game untouched. Continue resumes the saved game with `GameScreen.start_game()`, with no drop or merge animation.
- The Android back button (`NOTIFICATION_WM_GO_BACK_REQUEST`, with `application/config/quit_on_go_back` off) is resolved by `ScreenNavigation.resolve_back()` from the current screen and the game state (`GameScreen.get_navigation_state()`); `Main` applies the answer: quit from home, pause from a game in progress, resume from the pause, back to the main page of the pause from its settings, home from the tutorial, the game over screen, the settings and the shop (see [0006](decisions/0006-back-button-and-overlays.md)).
- It asks `AudioManager.start_music()` once at launch, so the music never restarts between screens.

### `scripts/save/` — saved game data

| Script | Responsibility |
|--------|----------------|
| `current_game_store.gd` | `CurrentGameStore`: the game in progress in the `current_game` save section, with the record before that game (`best_score_before_game`), so a resumed game still knows whether it beat the record. `load_session()` returns null when none is saved, and discards (with a warning) a saved game that `GameSession.create_from_data()` rejects, keeping the rest of the save. `store()` replaces the section, `erase()` removes it |
| `record_book.gd` | `RecordBook`: best score and highest tile level over every real game, in the `record` section; `submit()` only raises them |
| `coin_wallet.gd` | `CoinWallet`: the player's coins, in the `wallet` section (`coins`). `add_coins()` and `try_spend()` refuse an amount of 0 or less (assert); `try_spend()` returns false and changes nothing when the balance is too low. A negative or non-integer saved value reads as 0. Each change emits `WalletEvents.coins_changed` |

### `scripts/ui/` — presentation

| Script | Responsibility |
|--------|----------------|
| `palette_screen.gd` | `PaletteScreen`: base of full screens. Applies the active palette (interface theme, background color and image) and rebuilds it on `Settings.palette_changed`; `_apply_screen_palette()` adds what a screen draws itself |
| `settings_rows.gd` | `SettingsRows`: every setting row, defined once (`scenes/ui/settings_rows.tscn`): sound, music, vibration and screen shake toggles (group `TOGGLES`), and language French / English (`LANGUAGE`), each written to `Settings` at once. The theme is chosen in the shop (`ShopScreen`). `shown_groups` picks the groups a screen shows |
| `shop_screen.gd` | `ShopScreen` (`scenes/ui/shop_screen.tscn`), laid out after `docs/maquettes/*/theme_catalog_*.png`: title (`ModalTitle`) and subtitle (`ShopSubtitle`), a scroll list (scroll bar hidden, touch scrolling kept) with one `ThemeCard` per entry of its `catalog` (`Settings.THEME_CATALOG`, set before it enters the tree; tests give one with a paid theme), in catalog order, then Back outside the list (`IconActionButton`, `HomePrimaryButton`, about half the width; `back_requested`), and a `CoinCounter` in the top right corner, in its own `SafeAreaMargin`. The list keeps a margin of `SHOP_CARD_GLOW_SIZE` around the cards, so the scroll area does not clip their glow. Buy calls `ThemeShop.try_buy()` and never equips; Equip calls `ThemeShop.equip()`, and `Settings.palette_changed` recolors the screen. The cards are built once, then refreshed on `WalletEvents.coins_changed` and on each palette change. Every button plays `ui_click` |
| `theme_card.gd` | `ThemeCard` (`scenes/ui/theme_card.tscn`): `ThemePreview` on the left; on the right the name (`ShopCardName`) beside the check badge (`ShopCheckBadge`, `icon_done.svg`), the description (`description_key`, `ShopCardDescription`, two lines at most, ellipsis beyond, always two lines high) and one action row of fixed height, so every state gives the same card height. `resolve_state()` picks `EQUIPPED` (`ShopCardEquipped`: accent border and glow, badge shown, disabled "Equipped"), `OWNED` ("Equip", `ShopEquipButton`, full width) or `FOR_SALE` (coin icon and price on the left, "Buy", `ShopBuyButton`, 60 % of the row, disabled when the balance is too low, price still shown); emits `action_pressed` |
| `theme_preview.gd` | `ThemePreview`: a tiny board in the theme of its `palette`, whatever the active theme: its `background`, then its `frame_fill` and `frame_border` in the `ShopPreviewFrame` shape, and tiles 2, 8, 64 and 1024 in a 2 × 2 grid, drawn with a `TilePainter` of that palette |
| `settings_screen.gd` | `SettingsScreen`: every `SettingsRows` group in a scroll container, and Back (`back_requested`). Later settings (phase 4) join `SettingsRows` as a new group |
| `home_screen.gd` | `HomeScreen`: `LogoMark` and title (`HomeTitle`), Play, and Continue when a game is saved, as primary `IconActionButton`s; below them, Tutorial, Themes (`icon_palette.svg`) and Settings as secondary ones; a `CoinCounter` in the top right corner, in its own `SafeAreaMargin` over the layout. Every button plays `ui_click`. Logo size and button heights are constants. Emits `play_requested`, `continue_requested`, `tutorial_requested`, `shop_requested`, `settings_requested`. Each row lays its buttons side by side (Play left, Continue right; Tutorial, Themes, Settings; same width) when the widest button's minimum width times the button count fits the screen width inside the margins, else stacks them (Continue on top), checked again on resize and language change. On the base width the three secondary buttons stack |
| `game_over_summary.gd` | `GameOverSummary`: pure values of the game over screen (score, record, highest tile) and whether the record was just beaten, against the record before the game; a previous record of 0 is never announced as beaten |
| `game_over_panel.gd` | `GameOverPanel`: overlay over the finished game, in the modal style: scrim and `ModalCard`, the palette `score_icon` as a large crown straddling the top edge of the panel with a `CrownHalo` behind it, the title (`GameOverTitle`), the new record message when `GameOverSummary` reports one, three stat rows (score, record, highest tile; icon, caption and right-aligned plain integer, each row in its own tint; the value takes `game_over_score_value`, `game_over_record_value` or `game_over_tile_value`, or the shared `game_over_stat_value` while they stay transparent, as in Paper and Night), then Play again (`ModalPrimaryButton`, new game in one tap) above Menu (`ModalSecondaryButton`, `menu_requested`, which `GameScreen` turns into `home_requested`). `RewardSlot`, between the stat rows and the buttons, shows the `CoinRewardResult` that `GameScreen` passes to `show_summary()`: coin icon and "+N" (`UI_COINS_EARNED`, `CoinGainValue`), beside a `CoinCounter`; hidden when the reward is null. The "+N" pops once the panel has appeared (`Tween` on its scale), only while screen shake is on. The rewarded ad joins the slot in phase 4. Each `show_summary()` fades and grows the panel in (`Tween`) and throws one `ConfettiBurst` in the tile colors from the top edge of the panel, one frame later, once the panel is laid out; the record burst when the record is beaten. While the panel shows, the halo turns and breathes in a loop (tweens on its rotation and opacity only, never redrawn). Hiding the panel (Play again; Menu and back free the screen) stops the tweens and clears every confetti piece. `apply_palette()` takes the crown, icons, halo and confetti colors from the palette |
| `screen_navigation.gd` | `ScreenNavigation`: pure decisions of where the back button leads, per screen and game state (`PLAYING`, `PAUSED`, `PAUSE_SETTINGS`, `TUTORIAL`, `GAME_OVER`), and whether an inactive app pauses the game |
| `pause_panel.gd` | `PausePanel`: overlay over the paused game: a scrim (`ModalScrim`), then a `ModalCard` centered in the safe area, with a title between two rules (`ModalTitle`, `ModalTitleRule`) naming the shown page. Main page, one `IconActionButton` per row: Resume (`ModalPrimaryButton`), Menu (keeps the game for Continue), Restart (abandons the game, which counts for the record) and Settings (`ModalSecondaryButton`). Settings page: the `TOGGLES` group of `SettingsRows` and Back to the main page. Button heights are constants. A new pause always opens on the main page |
| `home_menu.gd` | `HomeMenu`: pure decisions of the home screen: choices offered, their order, and whether to stack them from the buttons' real minimum widths |
| `game_screen.gd` | `GameScreen`: owns the `GameSession` (`start_new_game()`, `start_tutorial()`, or `start_game()` with a given session and the record before it), forwards released columns, saves each real turn (see Save flow), starts the playback of each turn, refreshes the HUD when it ends and shows the game over overlay when the game is over, opens and closes the pause (`open_pause()`, `close_pause()`, and `close_pause_settings()` back to its main page; the HUD pause button shows outside the tutorial), emits `turn_playback_finished` and `home_requested`, reports its state to `ScreenNavigation` (`get_navigation_state()`), redraws the tiles and combo outline with the palette and passes it to the game over overlay |
| `board_view.gd` | Draws the board frame (`StyleBoxFlat`: palette `frame_fill`, `frame_border` border and glow), the empty cells then the tiles (so no cell covers a tile glow), the displayed board, moving tiles, merge pulses and the placement ghost, dims unplayable columns, maps a touched column to the played left column (`find_played_column`), emits `column_released`, `pressed_while_locked`, and `unplayable_column_released` on a release over a column that cannot take the pair. The mirror axis (a `Panel` with a rounded, glowing `StyleBoxFlat`, placed when the board or the view size changes) and board effects such as particles sit in a child effects layer |
| `confetti_burst.gd` | `ConfettiBurst`: one reusable one-shot `CPUParticles2D` of generated rounded rectangles, spinning, each in one of the given colors at random, thrown from a line (`place_line()`); `clear()` removes every piece at once |
| `merge_particles.gd` | `MergeParticles`: fixed pool of one-shot `CPUParticles2D` emitters with a generated disc texture; bursts never exceed the live particle cap |
| `board_style.gd` | `BoardStyle`: frame padding, corner radius, border and glow, cell gap, axis width and glow, loaded from `data/board_style.tres` |
| `tutorial_panel.gd` | `TutorialPanel`, under the board (`TutorialCard`): a step's instruction beside the tap icon (`tutorial_icon`) with Skip, then its explanation with Skip and Next, or Done alone on the last step (Skip would do the same). Text in `TutorialMessage`, centered and wrapped; buttons are `IconActionButton`s, Next and Done primary, Skip secondary. `fit_to_steps()` (from `GameScreen.start_tutorial()`) sets the message height to the tallest step text at its width, measured with the font again on resize, so the panel keeps one height through both states and the three steps. Emits `next_requested`, `skip_requested` |
| `tutorial_hint_config.gd` | Tutorial highlight pulse period, loaded from `data/tutorial_hint.tres` |
| `resolution_playback.gd` | Replays a turn's resolution events with simple tweens, emits `tiles_landed`, `chain_link_merged` and `playback_finished` |
| `game_feedback.gd` | `GameFeedback`: plays the sound and vibration of each game event (see Audio feedback) |
| `crown_halo.gd` | `CrownHalo`: soft disc and thin rays fading to transparent through vertex colors, in one palette color (transparent draws nothing); drawn once per size or color; `GameOverPanel` animates only its transform and opacity |
| `game_over_effects_config.gd` | Confetti, panel appearance and coins earned pop of the game over screen, loaded from `data/game_over_effects.tres` |
| `resolution_playback_config.gd` | Playback durations, curves and chain intensity, loaded from `data/resolution_playback.tres` |
| `combo_text.gd` | `ComboText`: combo message text, with the decimal separator of the current language |
| `tile_swatch.gd` | Draws one tile (current, reflection, next previews) |
| `color_contrast.gd` | `ColorContrast`: WCAG 2 contrast ratio and relative luminance |
| `tile_painter.gd` | Draws a tile with the active palette (text color of each level picked once, when the painter is built): a rounded `StyleBoxFlat` with a darker bottom relief, a glow in its color (`tile_glow_opacity`, 0 removes it), and its value sized with `TileTextConfig`. A tile below the palette's `min_tile_edge_contrast` against the empty cells or the frame gets a thin outline in a darkened relief color that reaches it, decided once per level. A palette with `tile_rim_colors` (empty by default, so Paper and Night are unchanged) gives every tile a light rim of its own color all around instead, without relief; the rim then stands for the tile against the board. Empty cells use the same shape with a thin light outline (`cell_outline`). `draw_tile_shape()` draws the same rounded shape, filled or outlined, for merge pulses and tutorial highlights |
| `theme_palette.gd` | `ThemePalette`: colors of one theme, for the interface, the HUD, the home logo and buttons, the pause and game over overlays (`modal_*`, `game_over_*`), the coin counter and the coins earned (`coin_*`, text at 4.5:1 or more on its background), the shop cards and buttons (`shop_*`, sampled from the mockups; every text at 4.5:1 or more on its fill, disabled buttons aside), the board and tiles (a dark and a light value text, `pick_tile_text_color()` takes the one with the higher contrast on a level). Every HUD, frame and axis border, glow and soft shadow is a color of its own (transparent for none), and the HUD icons are textures of the palette |
| `tile_text_config.gd` | Font and size limits of tile values, loaded from `data/tile_text.tres` |
| `ui_theme_builder.gd` | Builds the interface `Theme` (label color, panels, buttons, and the `SecondaryButton` variation, outlined, for secondary actions, and `ChoiceButton`, based on it, for settings toggles and choices, filled when on) of a palette on top of `assets/themes/base_theme.tres`. Also the home title `HomeTitle` (bold, glow as a widened label shadow like the HUD values) and the home button variations `HomePrimaryButton` (Play, Continue; with a glow or soft shadow) and `HomeSecondaryButton` (Tutorial, Settings), the modal variations shared by the pause and game over overlays (`ModalScrim`, `ModalCard`, `ModalTitle` and its `ModalTitleRule`, `ModalPrimaryButton` with a glow or soft shadow, `ModalSecondaryButton`), the game over title `GameOverTitle` (smaller than `ModalTitle`, so the French title fits) and stat rows (`GameOverScoreRow`, `GameOverRecordRow`, `GameOverTileRow`, `GameOverStatCaption`, `GameOverRecordCaption`, `GameOverStatValue`, and `GameOverScoreValue`, `GameOverRecordValue`, `GameOverTileValue` based on it), every `IconActionButton` variation with hover like normal and no focus frame, the tutorial panel variations `TutorialCard` (`ModalCard` with less padding) and `TutorialMessage`, the coin variations `CoinCounter` (bordered capsule), `CoinRow` (icon beside its amount), `CoinCounterValue` and `CoinGainValue`, the shop variations (`SHOP_*` constants, measured on the mockups) `ShopSubtitle`, `ShopCard` and `ShopCardEquipped` (same padding, thicker accent border and glow), `ShopPreviewFrame` (radius and border width only), `ShopCardName`, `ShopCardDescription`, `ShopPrice`, `ShopCheckBadge`, and `ShopEquipButton` and `ShopBuyButton` (bold text, a highlight faded into the base color over the top half through a blended top border, grey `disabled` state), and the HUD variations (see HUD); every HUD, home and modal radius, border, margin, font size and glow is a named constant there |
| `icon_action_button.gd` | `IconActionButton` (`scenes/ui/icon_action_button.tscn`): menu `Button` that draws a round badge with its `badge_icon` on the left and a chevron on the right, both in the style's content margins, so its minimum width counts them. Badge style and icon color are theme items of its variation (`badge`, `badge_icon_color`); a palette `*_badge_border` color turns the badge into a ring (`ICON_BUTTON_BADGE_BORDER_WIDTH`), transparent by default as in Paper and Night; the chevron takes the text color at `CHEVRON_OPACITY` |
| `modal_card.gd` | `ModalCard`: `PanelContainer` of an overlay that takes `WIDTH_RATIO` of its parent's width, measured inside the safe area, on every resize |
| `logo_mark.gd` | `LogoMark`: the game logo drawn in `_draw()` with the palette `logo_*` colors: two overlapping translucent circles, a four-pointed star above and below, a dash on each side, and in Night a glow of thin concentric rings fading outwards (no blur). Lengths are ratios of its height; redrawn only on resize and `Settings.palette_changed` |
| `coin_counter.gd` | `CoinCounter` (`scenes/ui/coin_counter.tscn`): coin icon (`assets/icons/icon_coin.svg`) and the wallet balance in a `CoinCounter` capsule, as `CoinAmountFormat.format_compact()` writes it with the decimal separator of the language. Reads `CoinWallet.get_coins()` when ready, then follows `WalletEvents.coins_changed`; the label text only changes with the value or the language. The amount keeps the width of the widest compact text ("9999", "99,9k", "999k", "9,9M", "999M" with every digit as the widest one of its font), measured on each theme or language change, one frame later: the counter hears of a new theme before its label, whose cached font is still the old one. The counter never resizes with the balance; from a billion on, the text is clipped. On the home screen and the shop, top right, and on the game over screen |
| `coin_amount_format.gd` | `CoinAmountFormat`: short form of a balance, pure. Exact below 10 000; thousands with `k` (one decimal below 100k: `12,5k`, `100k`), millions with `M` (one decimal below 10M: `1,2M`, `12M`); a zero decimal is left out, values are rounded down, a negative one shows 0. The suffixes are not translated. Only the balance is compacted: shop prices and the coins earned stay exact |
| `pause_button.gd` | `PauseButton`: square HUD button that draws its pause symbol, two rounded bars in the font color |
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

### `scripts/themes/` — theme catalog and purchase

| Script | Responsibility |
|--------|----------------|
| `theme_entry.gd` | `ThemeEntry` (`Resource`): `id` (saved, never renamed), `palette`, `price` (0 = free, always owned), `display_name_key`, `description_key` (two lines at most in the shop) |
| `theme_catalog.gd` | `ThemeCatalog` (`Resource`, `data/theme_catalog.tres`): ordered entries and `default_id`; `find_entry()` returns null for an unknown id |
| `theme_shop.gd` | `ThemeShop` (`RefCounted`, catalog injected): `is_owned()`, `try_buy()` (refuses an unknown or owned theme and a short balance; `CoinWallet.try_spend()` then the `owned` list, in the same frame), `equip()` (owned themes only, writes `Settings.palette_name`, whose `palette_changed` recolors the screens) and `resolve_equipped_id()`, the only place that turns a saved id into the theme shown. Buying does not equip. See [0008](decisions/0008-themes-and-purchase.md) |

### `scripts/autoload/` — platform services

Loaded in this order; each one may use the ones above it.

| Autoload | Responsibility |
|----------|----------------|
| `AppLifecycle` | Turns `NOTIFICATION_APPLICATION_PAUSED` / `FOCUS_OUT` and `RESUMED` / `FOCUS_IN` into `is_active` and the `deactivated` / `activated` signals (the last notification wins). The only place that reads these notifications (see App lifecycle) |
| `SaveManager` | Versioned local save in `user://save.cfg` (see [0002](decisions/0002-save-format.md)). `get_value` / `set_value` by section and key. Changes made in the same frame make one write at the end of the frame, and an unchanged save is not written again; `flush()` writes at once, and runs on `AppLifecycle.deactivated`. Each write goes through a checked temporary file and keeps the previous save as a backup; a missing, empty, unreadable or newer save falls back to the backup, then to an empty save (see [0005](decisions/0005-save-writing.md)) |
| `WalletEvents` | Only carries `coins_changed(new_total)`, emitted by the static `CoinWallet` |
| `Settings` | Sound, music, vibration, screen shake, language, theme (`palette_name`: an id of `THEME_CATALOG`; read through `ThemeShop.resolve_equipped_id()`, so an unknown or unowned saved id shows the default theme; `get_palette()` returns its palette) and linear volume per audio bus (`get_bus_volume` / `set_bus_volume`, 0 to 1), stored in the `settings` section. Emits `changed`, and `palette_changed` for the theme |
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
- `scenes/ui/home_screen.tscn`: logo, title, the Play / Continue buttons, then the Tutorial / Themes / Settings buttons, as one block centered slightly above the middle (stretch ratios of the spaces above and below); a taller screen spreads the spaces, a wider one widens the buttons.
- `scenes/ui/settings_screen.tscn`: `SettingsRows` and Back.
- `scenes/ui/settings_rows.tscn`: the setting rows, by group.
- `scenes/game/game_screen.tscn`: HUD (see HUD), previews, board with the centered combo label, tutorial panel, pause and game over overlays.
- `scenes/game/tutorial_panel.tscn`: tap icon, tutorial message, Skip and Next buttons.
- `scenes/game/game_over_panel.tscn`, `scenes/game/pause_panel.tscn`: game over and pause overlays of the game screen.

### Data and assets

- `data/balancing.tres`: every gameplay value (see [balancing.md](balancing.md)).
- `data/resolution_playback.tres`: playback durations (see [balancing.md](balancing.md)).
- `data/game_over_effects.tres`: game over confetti and appearance (see [balancing.md](balancing.md)).
- `data/tutorial_hint.tres`: tutorial highlight pulse period.
- `data/palette_paper.tres`, `data/palette_night.tres`: the two default themes (see [0003](decisions/0003-art-direction.md)).
- `data/theme_catalog.tres`: every theme with its palette, price and name key (`paper` and `night`, free; default `paper`).
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

## HUD

The HUD above the board holds only the score, the record and the pause button; the highest tile shows on the game over screen. Its look follows the visual reference in `docs/maquettes/`. Values are plain integers, without thousands separator, and seven digits fit their half at the base width in every language (`tests/test_game_hud.gd`).

```
HudRow (HBoxContainer, HudRow)
├ Capsule (PanelContainer, HudCapsule: hud_capsule fill, hud_capsule_border, hud_capsule_glow)
│ └ Halves (HBoxContainer)
│   ├ ScoreMargin (HudScoreMargin: inset from the capsule) → ScorePanel (HudScorePanel: hud_panel fill, hud_score_panel_border)
│   │   └ Row (HudPanelRow) [ScoreIcon, Stack [Caption (HudScoreCaption), ScoreLabel (HudScoreValue)]]
│   ├ Separator (VSeparator, HudSeparator)
│   └ RecordPanel (HudRecordPanel: hud_record_panel_border and glow, flush with the capsule)
│       └ Row (HudPanelRow) [RecordIcon, Stack [Caption (HudRecordCaption), BestLabel (HudRecordValue)]]
└ PauseButton (PauseButton)
```

- Both halves expand equally. The record panel has the capsule's corners and covers its right edge. In Night, the panels are transparent and borderless, so the HUD reads as one dark blue capsule with a cyan border and the separator between both halves. In Paper, panels and borders take the capsule color, so the HUD reads as one cream capsule with a beige separator and a soft shadow, and the pause button is filled.
- Glows and soft shadows are `StyleBoxFlat` shadows without offset; value glows are label shadows widened by `shadow_outline_size` (no blur). Nothing is redrawn while the values do not change.
- Icons come from the palette (`score_icon`, `record_icon`): the crown in both themes, the violet trophy in Night and the gold one (`icon_record_trophy_gold.svg`) in Paper. The trophies are imported at 0.75 scale (96 px); the crown at 2.0 (256 px) with mipmaps, since the game over screen shows it large. Shown at `GameScreen.HUD_ICON_SIZE`, with mipmap filtering so the large crown stays clean when reduced.

Under the HUD, the tile, mirror and next previews (`TileSwatch`) sit in three columns of the same width (`GameScreen.PREVIEW_COLUMN_WIDTH`, `PreviewColumn` variation), so the mirror preview is centered on the screen, above the axis. The next tile is smaller and aligned on the bottom of the others. Captions use the `PreviewCaption` variation (Fredoka Bold).

## Board layout

`BoardView` fits the board, inside its frame padding, to its width. Cells stretch vertically up to `MAX_CELL_HEIGHT_RATIO` (1.3) to fill the free height, so a board with more columns stays about as tall. When the height is the limit, cells stay square. The board is centered in `BoardView`.

## Placement ghost

While a finger is down on the board, or the mouse hovers it on PC, `BoardView` asks `GameSession.preview_placement()` for the played left column under the pointer (either half) and draws the tile and its reflection where they will land, linked by a thin line across the axis. `TilePainter.draw_ghost_tile()` gives a ghost a faint fill, a solid outline and the value in the tile color, without the relief of a placed tile. The ghost fades in, pulses gently, and slides with its reflection as mirror images when the finger changes column; a new slide starts from the drawn position. The slide is visual only: a release always plays the column under the finger. Its tweens run only while the ghost is shown, and are killed when it disappears (release, locked board, unplayable column). The ghost is hidden while input is locked or on a column that cannot take the tile and its reflection (`BoardView.is_ghost_visible()`).

## Resolution playback

- `ResolutionPlayback` builds one `Tween` for the whole turn: placed tiles drop from the top row, speeding up, and squash on landing, each chain link flashes its groups, slides them onto their result cells and pops the results, later links faster and with a larger pop (`ResolutionPlaybackConfig.get_chain_intensity()`); each result tile throws a particle burst in its palette color, larger on later links, and from a configured link the board shakes (`BoardView.set_shake_offset()`, which moves the drawing and the effects layer, never the layout), unless `Settings.is_screen_shake_enabled` is off, fallen tiles slide down and squash the same way, with a short pause after each step. From link 2 on, one combo label centered on the board shows the multiplier (`x2`, `x2,5` in French), with a word from configured links, and pops at each link; it stays `combo_hold_duration` after the turn ends, and disappears at once on a skip or when the next turn starts.
- The displayed board only changes through `ResolutionEvent.apply_to()`; the presentation never applies game rules.
- A turn longer than `max_chain_duration` plays faster: the tween speed scale is raised so the whole turn fits.
- While playing, the board ignores taps. A press on the board skips: the tween stops, the remaining events are applied, and `playback_finished` fires. Outside the tutorial this unlocks the board at once, so the same press plays the next tile on release. It fires exactly once per turn, whether the playback ends or is skipped, any number of times.
- At the end, the board view shows the session board again, which matches the replayed board.

## Audio feedback

`GameFeedback` observes the playback and the board, like the animations, and never touches the core:

- `ResolutionPlayback.tiles_landed` (the placed pair lands): `placement`, and the `placement` pulse.
- `ResolutionPlayback.chain_link_merged(chain_link)`: one sound per link however many groups merge, `merge` on link 1, `chain` after, at `AudioConfig.get_chain_pitch_scale(chain_link)`; the `HapticsConfig.get_chain_link_pulse(chain_link)` pulse.
- `BoardView.unplayable_column_released`: `unplayable_column`.
- `game_screen` calls `play_game_over()` when a turn ends the game, played or skipped (sound and `game_over` pulse), and `play_ui_click()` on its buttons and the tutorial buttons.

Both playback signals are tween callbacks: a skip kills the tween, so the remaining steps never play their sounds late, and the next turn plays normally. `AudioManager.effect_played` reports every sound played.

## Tutorial flow

1. `GameScreen.start_tutorial()` runs when the player taps Tutorial on the home screen, the only way to open it. It replaces the displayed session with the step's `TutorialStep.create_session()`; the saved game in progress is left untouched.
2. `BoardView.show_tutorial_hint()` pulses the target column, its mirror, the step's cells and the axis, and sets `restricted_column` so only the target column (or its mirror) can be played.
3. On release, `GameScreen` plays the turn like any other, through `ResolutionPlayback`. The hint is cleared.
4. On `playback_finished`, the board stays locked and `TutorialPanel` shows the explanation. Next loads the following step; after the last one (Done), or on Skip, `GameScreen` emits `home_requested` and `Main` shows the home screen; the saved game is untouched and Continue still offers it.

## Save flow

What is saved, in `user://save.cfg` (format: [0002](decisions/0002-save-format.md), writing: [0005](decisions/0005-save-writing.md)):

- `record`: best score and highest tile level (`RecordBook`).
- `wallet`: the player's coins (`CoinWallet`).
- `themes`: `owned`, the ids of bought themes (`ThemeShop`); free themes are never written. The equipped theme stays `settings/palette_name`.
- `settings`: every `Settings` value, written on each change.
- `current_game`: the game in progress, `GameSession.to_data()`, and the record before it (`CurrentGameStore`). Never the tutorial.

When:

- After each real turn, right after `play_column()` and before the playback: the session already holds the final state, so a kill during the animation keeps the turn. The record is raised, then the game is stored, or erased if the turn ended it.
- When the turn ends the game: record, then `CoinWallet.add_coins()` with `CoinReward.calculate_coins()`, then `CurrentGameStore.erase()`, all in the same frame, so one write holds both the coins and the erased game (see [0007](decisions/0007-coins-and-wallet.md)). `GameScreen.get_coin_reward()` keeps a `CoinRewardResult` (`coins_earned`, `total_after`) for the game over screen. The tutorial and an abandoned game pay nothing.
- `start_new_game()` counts the saved game for the record, then replaces it with the new game. The tutorial never touches the save.
- Continue rebuilds the saved game with `GameSession.create_from_data()` and shows its board at once, without animation. A game the core rejects is discarded; the record and settings stay.

## App lifecycle

Background, screen lock, incoming call, notification shade and, in phase 4, full-screen ads all make the app inactive. Nothing assumes the player left: being inactive only makes the app safe to kill or to leave paused.

On `AppLifecycle.deactivated`:

- `SaveManager.flush()` writes the waiting changes; the game itself is already saved after each turn.
- `GameScreen` cancels a finger still down (`BoardView.cancel_press()`), so its release after the return plays nothing, and skips the running playback to the final state (`ResolutionPlayback.skip()`), so the app never comes back half animated. A skip plays no landing or chain sound. During a game in progress it then opens the pause (`ScreenNavigation.should_pause_when_inactive()`, see [0006](decisions/0006-back-button-and-overlays.md)).
- `AudioManager` pauses the music (`MusicState`).

In the background, Android stops the Godot main loop: tweens and processing freeze until the return. With only the focus lost (shade, call screen on top), the loop runs, but the board is idle: the playback was skipped. On `activated`, the music resumes; the game stays paused until the player resumes it.

## Tests

`tests/` holds GUT tests for the core, the tutorial scenarios, the resolution playback, board input, the tutorial flow on the game screen, the tutorial panel layout, saving, the home screen and the navigation (`test_*.gd`) and fixtures (`BoardFixture` describes boards as text, `BalancingFixture` builds explicit configs, `SaveFixture` points `SaveManager` at a test file and deletes it afterwards, so no test touches the player's save; `ThemeSnapshotFixture` turns a palette into every theme item and tile color it gives). `tests/data/theme_snapshot_paper.json` and `theme_snapshot_night.json` keep those values as they were before the shop themes: `test_theme_snapshots.gd` checks that an optional palette field never changes Paper or Night. Regenerate them only on a deliberate change to these two themes. Tests and GUT are excluded from exports.
