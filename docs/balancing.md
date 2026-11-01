# Balancing

All gameplay values live in `data/balancing.tres` (a `BalancingConfig` resource, editable in the Godot inspector). Values marked **[TO TEST]** are hypotheses from the spec.

| Parameter | Default | Controls |
|-----------|---------|----------|
| `column_count_per_side` | 3 | Columns on each side of the axis |
| `row_count` | 6 | Rows per column **[TO TEST]** (6×7, 6×5) |
| `max_tile_level` | 12 | Highest level; tiles at this level do not merge |
| `spawn_weight_tiers` | see below | Draw weights per level, chosen by highest level reached **[TO TEST]** |
| `chain_multiplier_step` | 1.0 | Multiplier added per chain link (×1, ×2, ×3 …) **[TO TEST]** |
| `is_cross_axis_merge_enabled` | true | Lets G3 and D1 tiles merge across the axis **[TO TEST]**. Not written in the `.tres` while it equals the script default (true) |
| `large_group_bonus_per_extra_tile` | 1 | Points per tile beyond a pair in a merge group, before the chain multiplier |
| `is_distorted_reflection_enabled` | true | Turns the distorted reflection lever on or off |
| `distorted_reflection_period` | 3 | Every Nth placement has a distorted reflection **[TO TEST]** |
| `distorted_reflection_level_bonus` | 1 | Levels added to a distorted reflection |
| `coin_minimum_per_game` | 5 | Coins earned by a finished game, whatever its score **[TO TEST]** |
| `coin_score_per_coin` | 700 | Score points per coin; must stay above 0 **[TO TEST]** |
| `coin_level_bonus_start_level` | 6 | Highest level (64) from which each extra level earns a bonus **[TO TEST]** |
| `coin_per_level_above_start` | 4 | Coins per highest level above `coin_level_bonus_start_level` **[TO TEST]** |
| `rules_version` | 1 | Saved games made under another value are discarded on load (record and settings are kept) |

Bump `rules_version` only when old saved games would no longer make sense: a level changes meaning, or a rule changes what a board or a turn can be. Do not bump it for a weight, score or timing tweak: a saved game stays valid and simply continues with the new values. A board size change discards saved games on its own.

## Spawn weight tiers

Each `SpawnWeightTier` has a threshold, `min_highest_level`, and `level_weights`: the levels it can draw and their relative weights. The tier with the highest threshold not above the highest level reached in the game applies; the order of the list does not matter. The highest level reached never goes down, so a tier, once reached, stays for the rest of the game. Thresholds and weights are levels: tile value = 2^level.

| Tier | `min_highest_level` (highest tile) | Tile 2 (level 1) | 4 (2) | 8 (3) | 16 (4) | 32 (5) | 64 (6) |
|------|------------------------------------|------------------|-------|-------|--------|--------|--------|
| start | 0 (from the start) | 60 | 30 | 10 | – | – | – |
| advanced | 7 (128) | 50 | 30 | 15 | 5 | – | – |
| expert | 8 (256) | 40 | 30 | 20 | 8 | 2 | – |
| master | 9 (512) | 30 | 30 | 20 | 13 | 6 | 1 |

Weights are relative; they do not need to sum to 100. **[TO TEST]**

The expert and master tiers only concern good players. Bigger tiles earlier make levels climb faster, but also fill the board faster.

`tests/test_balancing_data.gd` checks the shipped data: a tier from level 0, distinct thresholds, at least one level per tier, levels within `max_tile_level`, positive weights, and the shipped thresholds (`SHIPPED_TIER_THRESHOLDS`), so a threshold lowered for a phone test fails the tests. Update `SHIPPED_TIER_THRESHOLDS` when the thresholds change on purpose.

## Coins

`CoinReward.calculate_coins()`:

```
coins = max(coin_minimum_per_game,
            floor(score / coin_score_per_coin)
            + max(0, highest_level - coin_level_bonus_start_level) × coin_per_level_above_start)
```

Calibration target: 25 coins per game on average, so about 20 games for a standard theme at 500 coins.

Simulator orders of magnitude (`base` scenario, 1000 games per strategy, 2026-11-01): `random` ≈ 8, `greedy` ≈ 25, `heuristic` ≈ 33 coins per game.

Reference points from the developer's own games (usual scores 9 500 to 15 000, record 20 450):

| Score | Highest tile | Coins |
|-------|--------------|-------|
| 9 500 | 256 | 21 |
| 12 000 | 256 | 25 |
| 15 000 | 512 | 33 |
| 20 450 | 512 | 41 |

The highest tile of these examples is assumed, not measured. The developer plays better than a new player: a beginner is closer to `random`, about 60 games for 500 coins. Theme prices will be set from the testers' games **[TO TEST]**.

| Theme | Price | |
|-------|-------|---|
| Paper, Night | 0 | Always owned |
| Neon | 500 | About 20 games at the target of 25 coins per game **[TO TEST]** |
| Wood | 500 | Same as Neon **[TO TEST]** |

Prices live in `data/theme_catalog.tres`.

## Resolution playback

Durations in seconds, in `data/resolution_playback.tres` (a `ResolutionPlaybackConfig`). They only change how a turn is shown, never its outcome.

| Parameter | Default | Controls |
|-----------|---------|----------|
| `drop_duration` | 0.12 | Drop of the placed tile and its reflection from the top row |
| `fall_duration` | 0.07 | Slide of tiles falling after a merge |
| `fall_transition`, `fall_ease` | Quad, In | Curve of drops and falls: tiles speed up as they fall |
| `landing_squash` | 0.1 | Landed tiles get this much wider and shorter, anchored at the bottom, then spring back |
| `landing_squash_duration` | 0.06 | Length of the landing squash |
| `merge_pulse_duration` | 0.05 | Flash on the groups of a chain link before they merge |
| `merge_converge_duration` | 0.08 | Slide of merged tiles onto the result cell |
| `merge_pop_duration` | 0.11 | Pop of the result tile: grows, then comes back with a small rebound |
| `merge_pop_scale` | 1.12 | Peak scale of the pop on the first chain link |
| `merge_pop_max_scale` | 1.3 | Peak scale of the pop at full chain intensity |
| `chain_intensity_curve` | Linear 0 to 1 | Chain intensity from link 1 to `chain_intensity_max_link` |
| `chain_intensity_max_link` | 5 | First link played at full intensity |
| `chain_max_speed_up` | 1.6 | Merge steps play this many times faster at full intensity |
| `particles_per_merge` | 8 | Particles thrown by each merge result on the first chain link |
| `particles_per_extra_link` | 4 | Particles added per further chain link |
| `max_particles_per_burst` | 24 | Largest burst |
| `max_live_particles` | 96 | Most particles on screen at once; bursts shrink or drop beyond it |
| `particle_lifetime` | 0.45 | Life of a particle, in seconds |
| `particle_min_size`, `particle_max_size` | 0.07, 0.12 | Particle diameter, in cell widths |
| `particle_min_speed`, `particle_max_speed` | 1.2, 2.2 | Launch speed, in cell widths per second |
| `particle_gravity` | 4.0 | Pull down, in cell widths per second squared |
| `particle_start_radius` | 0.4 | Particles start on this circle around the result tile center, in cell widths, so they leave from its edge |
| `shake_min_link` | 3 | First chain link that shakes the board |
| `shake_amplitude` | 0.04 | Shake amplitude on that link, in cell widths |
| `shake_amplitude_per_link` | 0.02 | Amplitude added per further link |
| `shake_max_amplitude` | 0.11 | Largest shake amplitude |
| `shake_duration` | 0.18 | Length of a shake; it runs beside the turn and never lengthens it |
| `combo_words` | 3: Nice!, 5: Great!, 7: Amazing! | Word shown before the multiplier from each chain link (translation keys) |
| `combo_pop_scale` | 1.2 | Peak scale of the combo message pop at each link |
| `combo_pop_duration` | 0.15 | Length of that pop |
| `combo_hold_duration` | 1.0 | Time the message stays after a turn played to the end; a skip or the next turn hides it at once |
| `ghost_fill_opacity` | 0.25 | Fill opacity of the placement ghost: the tile and its reflection before release |
| `ghost_outline_opacity` | 0.9 | Opacity of the ghost outline and value, in the tile color; much higher than the fill, so a ghost never looks like a placed tile |
| `ghost_outline_width` | 0.05 | Width of that outline, relative to the tile's shorter side (7 px with 3 columns per side, 5 px with 4, at 1080 px wide) |
| `ghost_link_opacity` | 0.3 | Opacity of the line linking the ghost tile to its reflection |
| `ghost_link_width` | 0.02 | Width of that line, in cell widths |
| `ghost_fade_in_duration` | 0.06 | Fade-in of the ghost when it appears; it disappears at once |
| `ghost_pulse_depth` | 0.3 | The ghost opacity dips by this ratio once per period while it is shown |
| `ghost_pulse_period` | 1.2 | Length of one ghost pulse |
| `ghost_slide_duration` | 0.08 | Slide of the ghost and its reflection to their new cells when the finger changes column |
| `step_pause` | 0.02 | Pause after each step |
| `max_chain_duration` | 2.5 | Longest playback of a turn; longer turns are sped up uniformly |

Measured on PC with these values: a drop alone 0.19 s; a single merge, drop and fall included, 0.60 s; a chain of 4 links 1.67 s. Validated on a phone (2026-10-27). Particles, shake and combo messages validated on a phone (2026-10-28): steady 120 FPS during playbacks up to 1.35 s.

## Game over effects

`data/game_over_effects.tres` (a `GameOverEffectsConfig`). Durations in seconds, lengths in pixels at the base resolution (1080 wide). One confetti burst at each game over, larger when the record is beaten; it never loops. The crown halo turns and breathes while the panel shows, through its transform and opacity only, never redrawn.

| Parameter | Default | Controls |
|-----------|---------|----------|
| `confetti_amount` | 36 | Confetti pieces of a game over |
| `record_confetti_amount` | 64 | Confetti pieces when the game beat the record |
| `max_confetti_amount` | 96 | Cap of both bursts, checked by the tests, so a modest phone keeps 60 FPS |
| `confetti_lifetime` | 2.6 | Life of a piece |
| `confetti_spread` | 80 | Pieces leave upward from the top edge of the panel, within this angle on each side, in degrees |
| `confetti_min_speed`, `confetti_max_speed` | 220, 460 | Launch speed, in pixels per second; at most about 160 px high, so the pieces spread around the top of the panel, under the HUD, then fall along its sides |
| `confetti_gravity` | 650 | Pull down, in pixels per second squared |
| `confetti_min_size`, `confetti_max_size` | 26, 42 | Length of a piece, twice its width |
| `confetti_max_spin` | 540 | Spin, either way, in degrees per second |
| `appear_duration` | 0.22 | Fade in of the panel |
| `appear_start_scale` | 0.92 | The panel grows from this scale to its size during the fade |
| `coin_pop_start_scale` | 0.6 | The "+N" coins earned grow back from this scale, once the panel has appeared; no pop while screen shake is off |
| `coin_pop_duration` | 0.3 | Length of that pop |
| `halo_turn_duration` | 20 | One full turn of the halo rays |
| `halo_breath_duration` | 2 | The halo fades from full opacity to `halo_min_opacity`, then back, each way in this time |
| `halo_min_opacity` | 0.75 | Faintest point of the halo breathing |

Not yet checked on a phone.

## Audio

`data/audio_config.tres` (an `AudioConfig`). Each event has a `SoundEffect`: its `stream`, a `volume_offset_db`, and a random spread per play in percent (`pitch_variation_percent`, `volume_variation_percent`; 0 turns it off).

| Event | Pitch / volume spread (%) | Plays when |
|-------|---------------------------|------------|
| `placement` | 4 / 10 | The placed tile and its reflection land; −6 dB offset |
| `merge` | 0 / 0 | Chain link 1 merges |
| `chain` | 0 / 0 | Chain link 2 and later merge, climbing the scale |
| `game_over` | 0 / 0 | The game ends |
| `ui_click` | 5 / 10 | A HUD or tutorial button is pressed; −6 dB offset |
| `unplayable_column` | 0 / 0 | The finger is released on a column that cannot take the tile and its reflection |

`merge` and `chain` never vary in pitch: the chain would go out of tune. Both play `merge.wav`.

Key: C major pentatonic (see [0004](decisions/0004-audio-key.md)). A higher note also plays shorter:

| Chain link | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 and later (cap) |
|------------|---|---|---|---|---|---|---|---|---|----|--------------------|
| Note | C5 | D5 | E5 | G5 | A5 | C6 | D6 | E6 | G6 | A6 | C7 |
| Merge sound length (s) | 0.269 | 0.240 | 0.214 | 0.180 | 0.160 | 0.135 | 0.120 | 0.107 | 0.090 | 0.080 | 0.067 |

Game over: E4 D4 C4 (329.6 to 261.6 Hz), as recorded, 0.703 s.

Sound effects validated on a phone (2026-10-29).

Sound files are normalized to the same perceived loudness: −20 dB K-weighted RMS (ITU-R BS.1770 filters) over the part within 30 dB of the peak, peaks under −1 dBFS. `volume_offset_db` then adjusts each event by ear.

| Parameter | Default | Controls |
|-----------|---------|----------|
| `scale_root_semitones` | 0 | Key of the game sounds, in semitones above C (0: C). Link 1 plays the merge sound on this root, in the octave of the file (C5: pitch scale 0.709); in another key, the game over sound, written in C, moves down to the root below C |
| `merge_sound_semitones_above_c` | 5.946 | Measured pitch of `merge.wav`: 737.7 Hz (F#5), 5.946 semitones above C5. Measure again when the file changes |
| `chain_scale_intervals` | [2, 2, 3, 2, 3] | Semitones climbed at each new link: C major pentatonic (C, D, E, G, A, C...), repeated per octave |
| `chain_max_pitch_link` | 11 | Later links keep the pitch of this one (two octaves up) |
| `chain_max_semitones` | 24 | The pitch never climbs more than this above link 1 (C7) |
| `player_pool_size` | 8 | Effect players created once and reused; when all are busy, the oldest sound is cut |
| `music_path` | `res://assets/audio/music/musical_ambiance.ogg` | Ambient music file, loaded only while the music is wanted |
| `music_volume_db` | −14 | Volume of the music player, kept below the effects so chain sounds stay clear. Not yet checked on a phone |
| `music_fade_in_seconds` | 1.5 | Fade-in when the music starts or comes back |
| `music_fade_out_seconds` | 1.0 | Fade-out when the music is stopped or disabled |

## Haptics

`data/haptics_config.tres` (a `HapticsConfig`). Each pulse is a duration in milliseconds and an amplitude from 0 to 1; phones that cannot set the amplitude only feel the duration, so a stronger pulse must also last longer. Checked on a phone with amplitude control (2026-10-30): values kept. Off with `Settings.is_vibration_enabled`.

| Parameter | Default | Controls |
|-----------|---------|----------|
| `placement` | 20 ms, 0.35 | When the placed pair lands |
| `merge` | 30 ms, 0.5 | Chain link 1; each later link climbs evenly towards `big_combo` |
| `big_combo` | 55 ms, 0.8 | Cap of the chain climb |
| `big_combo_min_link` | 4 | Chain link that reaches `big_combo`; later links stay there |
| `game_over` | 70 ms, 0.6 | When a turn ends the game; longer than `big_combo`, so the interval never drops it |
| `min_interval_ms` | 80 | A pulse closer than this to the last one sent is dropped, unless it is stronger |

## Tile text

`data/tile_text.tres` (a `TileTextConfig`): the value is drawn as large as fits both limits.

| Parameter | Default | Controls |
|-----------|---------|----------|
| `font` | Fredoka Bold | Font of tile values |
| `max_height_ratio` | 0.42 | Largest text height, relative to the tile height |
| `max_width_ratio` | 0.78 | Largest text width, relative to the tile width; "4096" is width-limited |

## Board style

`data/board_style.tres` (a `BoardStyle`). Colors come from the palette: frame `frame_fill` and `frame_border`, empty cells `empty_cell` and `cell_outline`, axis `axis`. Glows come from the palette too: `frame_glow` and `axis_glow` colors (transparent for none) and `tile_glow_opacity` (tiles, 0 for none). `min_tile_edge_contrast` (3.0 in every theme; every Wood tile is outlined, see 0009) is the least contrast of a tile against the empty cells and the frame; a tile below it gets an outline. Lower it to outline fewer tiles: at 1.3, Paper 128 and 256 lose theirs and the other outlines get lighter. A palette with `tile_rim_colors` gives every tile a light rim instead (`TILE_RIM_RATIO`, 4 % of the tile side, in `tile_painter.gd`), and the rim color must reach `min_tile_edge_contrast`.

Wood grain (see [0009](decisions/0009-wood-theme.md)): `surface_grain_opacity` (0.16, interface boxes, frame, empty cells) and `tile_grain_opacity` (0.08) set how far the grain darkens or lightens a surface at most. Raising one lowers the contrast of every text on that surface at the grain extremes: `tests/test_theme_palettes.gd` fails first on the 4, 1024 and Resume texts. Cost on a full board at 1080×2340 in Compatibility: +42 draw calls (99 to 141), +7 % primitives; setting `tile_grain_opacity` to 0 removes most of the draw calls. The hollow cell sizes are `CELL_INSET_SHADOW_RATIO` (8 % of the cell side) and `CELL_INSET_HIGHLIGHT_RATIO` (3 %) in `tile_painter.gd`.

| Parameter | Default | Controls |
|-----------|---------|----------|
| `frame_padding` | 23 | Space between the frame edge and the cells, in pixels |
| `frame_corner_radius` | 23 | Frame corner radius, in pixels |
| `frame_border_width` | 2 | Frame border width, in pixels |
| `frame_glow_size` | 14 | Frame glow size, in pixels |
| `cell_gap_ratio` | 0.07 | Space between two cells, relative to the cell width |
| `axis_width` | 5 | Mirror axis width, in pixels |
| `axis_glow_size` | 8 | Mirror axis glow size, in pixels |

Rendering cost of the glows, measured on a full board (36 tiles) at 1080×2340 in the Compatibility renderer: tile glows add about 4,100 primitives per frame (+28 %), the frame, axis and HUD glows about 430; the number of draw calls does not change (101). If the frame rate drops on a phone, set `tile_glow_opacity` to 0 first.

## Confusable tile colors

Night and Neon non-neighbor levels whose colors look alike with color vision deficiency (simulated, see [0003](decisions/0003-art-direction.md)). Only the value tells them apart. Kept in case a color vision deficiency mode is considered after launch (none in the MVP, see 0003). Paper is not checked for color vision deficiency (see 0003).

| Theme | Several deficiency types | Protanopia | Deuteranopia | Tritanopia |
|-------|------------------|------------|--------------|------------|
| Night | 4/256, 16/64, 64/4096 (deuteranopia, protanopia) | — | 2/8, 4/128, 16/4096 | 2/128, 16/1024, 32/2048 |
| Neon | 2/64, 8/32, 128/1024 (deuteranopia, protanopia); 2/512, 4/1024 (all three) | 2/128, 256/2048, 512/2048 | 4/128 | 8/1024 |

Neon also has two non-neighbor pairs close in normal vision: 64/512 (CIEDE2000 8.8) and 256/4096 (8.7, but the 4096 has a magenta rim).

Wood, like Paper, has no neighbor or color vision rule (see [0009](decisions/0009-wood-theme.md)); its close pairs are kept for the record. In normal vision: 16/64 (CIEDE2000 2.9, almost the same), 32/2048 (3.6), 512/4096 (4.4). With color vision deficiency (CIEDE2000 under 6): 32/2048 (0.4 deuteranopia, 0.9 protanopia, 2.0 tritanopia), 16/64 and 512/4096 (all three), 4/128 and the neighbors 16/32 (deuteranopia), 4/32, 4/64, 4/2048 and 8/1024 (protanopia), 32/128 and 128/2048 (tritanopia).

## Tutorial highlight

| Parameter | File | Default | Controls |
|-----------|------|---------|----------|
| `pulse_period` | `data/tutorial_hint.tres` | 1.2 | Seconds for one rise and fall of the tutorial highlight |

## Balance simulator

A command line tool that plays thousands of games with simple AIs on the core, to **compare** balancing settings. The AIs do not play like a human: use it to compare settings with each other, not to predict what a player will do.

Run it with the pinned Godot binary, headless:

```sh
GODOT=/path/to/godot ./run_simulation.sh                      # every scenario, 1000 games each
GODOT=/path/to/godot ./run_simulation.sh --games 200 --scenarios base,rows_5
```

| Option | Value | Default |
|--------|-------|---------|
| `--games N` | Games per scenario and strategy | 1000 |
| `--scenarios a,b` | Scenario names from `scenarios.json`, comma separated, no space | all |

An unknown scenario or a game count of 0 or less stops the run. Other values live in the files: first seed (`FIRST_SEED`, `simulation_runner.gd`), placement cap per game (`MAX_PLACEMENTS_PER_GAME`, `balance_simulator.gd`), seconds per placement (`SECONDS_PER_PLACEMENT`, `simulation_report.gd`), heuristic weights (`heuristic_strategy.gd`).

- **Strategies**: `random` (any playable column, the floor), `greedy` (most points now, then most empty cells) and `heuristic` (points, empty cells, merges prepared for the visible next tile on the tile and reflection sides, a penalty per column pair one cell from full; weights are constants in `heuristic_strategy.gd`). Strategies never read the game's random generator.
- **Paired games**: game *i* uses seed `1 + i` in every scenario and for every strategy, so differences come from the settings, not from luck. The same command gives the same numbers.
- **Scenarios**: `tools/simulation/scenarios.json`. Each has a `name` and `overrides`: `BalancingConfig` property names (`row_count`, `distorted_reflection_period`, `is_distorted_reflection_enabled`, …) applied to a copy of `data/balancing.tres` **as it is on disk**, plus `max_spawn_tier_threshold` to keep only the spawn tiers up to that level. Add a scenario by adding an entry; an unknown key stops the run. `base` plays the shipped config; every other shipped scenario changes one setting from it (rows, distorted reflection, spawn tiers), so its row compares with `base` alone. `data/balancing.tres` is never changed.
- **Output**: a table per scenario in the console (its header gives the effective board, distorted reflection and spawn tiers), and a CSV in `simulation_results/` (ignored by git), named with the date, the process id and the scenarios, so parallel runs never overwrite each other.
- **Reading the table**: placements per game (mean, median, quartiles, min, max); share of games whose highest tile reaches 64 to 2048; mean score; mean longest chain; share of placements that merge, and that merge across the axis; share of placements per left column (G1, G2, G3: the "always G3" risk of spec 4.5); games stopped by the placement cap (should stay 0); estimated minutes per game.
- **Estimated minutes** = mean placements × `SECONDS_PER_PLACEMENT` (`simulation_report.gd`). Its value, 2 s, is a starting point **to calibrate** on real games.
- The player's save is never written: the run points `SaveManager` at a temporary file and fails if `user://save.cfg` changed.
- The core has a single game over cause (no playable column pair), so the report has no cause column.

## Playtest results

Record Gate 1 findings and the values changed here.

- 2026-10-28: `column_count_per_side` set to 3 (was 4) after the developer's own play sessions. Gate 1: 1 tester of 5 so far.
