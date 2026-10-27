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
| `drop_duration` | 0.15 | Drop of the placed tile and its reflection from the top row **[TO TEST]** |
| `fall_duration` | 0.15 | Slide of tiles falling after a merge **[TO TEST]** |
| `merge_pulse_duration` | 0.3 | Pulse on the groups of a chain link before they merge **[TO TEST]** |
| `step_pause` | 0.08 | Pause after each step **[TO TEST]** |
| `max_chain_duration` | 2.5 | Longest playback of a turn; longer turns are sped up uniformly **[TO TEST]** |

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

None yet. Record Gate 1 findings and the values changed here.
