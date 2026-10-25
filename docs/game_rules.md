# Game rules (as implemented)

This file is the source of truth for the rules once coded. Values in *italics* are tunable in `data/balancing.tres` (see [balancing.md](balancing.md)).

## Board

- *6 rows*, *3 columns per side* of a central mirror axis: G1 G2 G3 | D1 D2 D3.
- The player only plays the left columns. G1 reflects to D3, G2 to D2, G3 to D1.
- G3 and D1 are orthogonal neighbors across the axis.
- Gravity pulls tiles down; each column falls independently.

## Tiles

- A tile has a level from 1 to *12*. Displayed value: 2^level (2 … 4096).
- The current tile and the next one are shown. Levels are drawn with weights that depend on the highest level reached in the game (*spawn weight tiers*).
- Draws use a seeded random generator: the same seed gives the same sequence.

## Turn

1. The player presses the board, can slide, and releases on a column of either half. A right column stands for its mirror left column: the tile always drops on the left and its reflection on the right. Releasing outside the board, or on a column whose pair is not playable, does nothing. While the finger is down (or the mouse hovers, on PC), a translucent ghost shows where the tile and its reflection will land. The six columns have touch zones of the same width, the axis gap included.
2. The tile drops in that column; its reflection drops in the mirror column, at the same moment.
3. Merges and chains are resolved.
4. Game over is checked, then the next tile becomes current.

The turn is computed at once, then shown step by step (drop, merges, falls). Input is locked during the playback; a press on the board skips to the end. The outcome is the same whether it is skipped or not.

## Merges

- Two or more orthogonally connected tiles of the same level form a group. Diagonals do not count.
- A group of any size becomes **one** tile of level +1. Groups of 3 or more can earn a bonus (*large group bonus*, 0 by default).
- Max-level tiles never merge.
- All groups found at the same moment merge together. Then gravity applies, and the board is checked again. Each new round of merges is one more **chain link**.

### Where the merged tile lands (in priority order)

1. **Axis rule.** If the group has cells on both sides of the axis, the result lands on the lowest left-side cell of the group (ties: closest to the axis). Every other cell of the group is emptied, on both sides.
2. **Action rule.** Otherwise, the result lands on a group cell that just moved: the placed tile, its reflection, a tile that just fell, or the result of the previous chain link. If several, the lowest one (ties: closest to the axis).
3. **Fallback.** Otherwise, the lowest cell of the group (ties: closest to the axis).

The result then falls with gravity if the cell below is empty.

### Consequences of the axis rule

- After a merge across the axis, the board is no longer symmetric: the right column loses its tile and the tiles above it fall, while the left column keeps the result.
- Playing G3 on an empty board always merges the tile with its reflection.

### Distorted reflection

When *enabled*, every *5th* placement gives a reflection of level +*1* (capped at the max level). The reflection preview in the HUD shows the level that will actually drop.

## Score

- Each merge earns `(2^result_level + extra_tiles × large_group_bonus) × chain_multiplier`, rounded.
  - `extra_tiles` = group size − 2.
  - `chain_multiplier` = 1 + (link − 1) × *step*: ×1, ×2, ×3 … with the default step of 1.
  - All merges of the same chain link share the same multiplier.
- The HUD shows score, best score of the session (in memory only) and highest tile reached.

## Tutorial

- Shown on every launch in Phase 1 (no save), and again with the "?" button, which abandons the current game.
- Three steps, each on a predefined board with a fixed tile sequence and its own rules (6×6 grid, no distorted reflection):
  1. **Drop**: on an empty board, the tile and its reflection drop on the outer columns.
  2. **Merge**: the same tile dropped on its twin merges on both sides.
  3. **Axis**: a matching tile waits in D1, with a tile above it so the reflection lands higher. Dropping in G3 merges the placed tile with the waiting one across the axis. The text then presents playing next to the axis as one option among others.
- Each step accepts only its target column, or a touch on its mirror; both are highlighted with a pulse, along with the cells involved and, in step 3, the axis.
- The explanation shows once the turn's playback has finished. "Skip" starts a real game at any time; "Play" does so after step 3.
- Tutorial scores do not count toward the session best score.

## Game over

- A left column is playable only if **both** it and its mirror column have at least one empty cell.
- **Known rule:** a tile cannot be dropped on a full column, even if it would merge with the top tile.
- Game over is checked after all chains are resolved; at that point no merge is possible, so no merge can free space. The game ends when no left column is playable.
- Restart starts a new game with a new random seed.
