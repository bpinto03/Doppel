# Balancing

All gameplay values live in `data/balancing.tres` (a `BalancingConfig` resource, editable in the Godot inspector). Values marked **[TO TEST]** are hypotheses from the spec.

| Parameter | Default | Controls |
|-----------|---------|----------|
| `column_count_per_side` | 3 | Columns on each side of the axis |
| `row_count` | 6 | Rows per column **[TO TEST]** (6×7, 6×5) |
| `max_tile_level` | 12 | Highest level; tiles at this level do not merge |
| `spawn_weight_tiers` | see below | Draw weights per level, chosen by highest level reached **[TO TEST]** |
| `chain_multiplier_step` | 1.0 | Multiplier added per chain link (×1, ×2, ×3 …) **[TO TEST]** |
| `is_cross_axis_merge_enabled` | false | Lets G3 and D1 tiles merge across the axis **[TO TEST]** |
| `large_group_bonus_per_extra_tile` | 0 | Points per tile beyond a pair in a merge group, before the chain multiplier |
| `is_distorted_reflection_enabled` | true | Turns the distorted reflection lever on or off |
| `distorted_reflection_period` | 5 | Every Nth placement has a distorted reflection **[TO TEST]** |
| `distorted_reflection_level_bonus` | 1 | Levels added to a distorted reflection |

## Spawn weight tiers

The tier with the highest `min_highest_level` not above the highest level reached applies.

| `min_highest_level` | Level 1 | Level 2 | Level 3 | Level 4 |
|---------------------|---------|---------|---------|---------|
| 0 | 60 | 30 | 10 | – |
| 7 | 50 | 30 | 15 | 5 |

Weights are relative; they do not need to sum to 100.

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
| `step_pause` | 0.02 | Pause after each step |
| `max_chain_duration` | 2.5 | Longest playback of a turn; longer turns are sped up uniformly |

Measured on PC with these values: a drop alone 0.19 s; a single merge, drop and fall included, 0.60 s; a chain of 4 links 1.67 s. Validated on a phone (2026-10-27). Particles, shake and combo messages validated on a phone (2026-10-28): steady 120 FPS during playbacks up to 1.35 s.

## Tile text

`data/tile_text.tres` (a `TileTextConfig`): the value is drawn as large as fits both limits.

| Parameter | Default | Controls |
|-----------|---------|----------|
| `font` | Fredoka Bold | Font of tile values |
| `max_height_ratio` | 0.42 | Largest text height, relative to the tile height |
| `max_width_ratio` | 0.78 | Largest text width, relative to the tile width; "4096" is width-limited |

## Board style

`data/board_style.tres` (a `BoardStyle`). Colors come from the palette: frame `panel`, empty cells `empty_cell`, axis `axis`.

| Parameter | Default | Controls |
|-----------|---------|----------|
| `frame_padding` | 16 | Space between the frame edge and the cells, in pixels |
| `frame_corner_radius` | 28 | Frame corner radius, in pixels |
| `cell_gap_ratio` | 0.06 | Space between two cells, relative to the cell width |
| `axis_width` | 6 | Mirror axis width, in pixels |

## Confusable tile colors

Non-neighbor levels whose colors look alike with color vision deficiency (simulated, see [0003](decisions/0003-art-direction.md)). Only the value tells them apart. Kept for a possible high-contrast mode in phase 3.

| Theme | Several deficiency types | Protanopia | Deuteranopia | Tritanopia |
|-------|------------------|------------|--------------|------------|
| Paper | 4/32, 8/512, 128/1024 | 4/4096, 8/2048, 32/4096 | — | — |
| Night | — | 64/4096, 4/256 | 64/4096 | 2/128, 4/32, 16/1024, 32/2048 |

## Tutorial highlight

| Parameter | File | Default | Controls |
|-----------|------|---------|----------|
| `pulse_period` | `data/tutorial_hint.tres` | 1.2 | Seconds for one rise and fall of the tutorial highlight |

## Playtest results

Record Gate 1 findings and the values changed here.

- 2026-10-28: `column_count_per_side` set to 3 (was 4) after the developer's own play sessions. Gate 1: 1 tester of 5 so far.
