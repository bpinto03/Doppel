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

## Haptics

`data/haptics_config.tres` (a `HapticsConfig`), in milliseconds. Starting values, to tune on a phone. Off with `Settings.is_vibration_enabled`.

| Parameter | Default | Controls |
|-----------|---------|----------|
| `placement_duration_ms` | 15 | Vibration when the placed pair lands |
| `merge_duration_ms` | 25 | Vibration of a chain link before `big_chain_min_link` |
| `big_chain_min_link` | 3 | From this chain link on, merges vibrate `big_chain_duration_ms` |
| `big_chain_duration_ms` | 60 | Vibration of a long chain link |
| `min_interval_ms` | 80 | A vibration closer than this to the previous one is dropped |

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
