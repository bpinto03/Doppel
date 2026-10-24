# Balancing

All gameplay values live in `data/balancing.tres` (a `BalancingConfig` resource, editable in the Godot inspector). Values marked **[TO TEST]** are hypotheses from the spec.

| Parameter | Default | Controls |
|-----------|---------|----------|
| `column_count_per_side` | 3 | Columns on each side of the axis |
| `row_count` | 6 | Rows per column **[TO TEST]** (6×7, 6×5) |
| `max_tile_level` | 12 | Highest level; tiles at this level do not merge |
| `spawn_weight_tiers` | see below | Draw weights per level, chosen by highest level reached **[TO TEST]** |
| `chain_multiplier_step` | 1.0 | Multiplier added per chain link (×1, ×2, ×3 …) **[TO TEST]** |
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

## Playtest results

None yet. Record Gate 1 findings and the values changed here.
