# Architecture

Game logic is separated from presentation. The core never touches nodes, scenes, audio, ads or files.

## Modules

### `scripts/core/` — pure logic (`RefCounted` / `Resource`)

| Class | Responsibility |
|-------|----------------|
| `BalancingConfig`, `SpawnWeightTier` | Typed balancing values, loaded from `data/balancing.tres` by the presentation layer and injected into the core |
| `BoardState` | Grid of tile levels (`0` = empty), mirror columns, drop, gravity |
| `TileGenerator` | Weighted draw of the current and next tile from an injected `RandomNumberGenerator`; optional scripted levels are drawn first |
| `MergeResolver` | Finds merge groups, picks where each result lands, loops merge + gravity until stable |
| `MergeGroup`, `ChainResult` | Data returned by the resolver |
| `MergeScoring` | Tile values, chain multiplier, merge points |
| `GameSession` | One game: turn flow, reflection, distorted reflection, score, highest level, game over. Starts on an empty board, or from a given board and scripted tile sequence |

### `scripts/ui/` — presentation

| Script | Responsibility |
|--------|----------------|
| `game_screen.gd` | Owns the `GameSession`, forwards column taps, refreshes the HUD, keeps the session best score in memory |
| `board_view.gd` | Draws the board, dims unplayable columns, emits `column_tapped` |
| `tile_swatch.gd` | Draws one tile (current, reflection, next previews) |
| `tile_painter.gd` | Shared tile drawing and level colors |

### Scenes

- `scenes/main.tscn`: entry point, hosts the game screen.
- `scenes/game/game_screen.tscn`: HUD, previews, board, restart button.

### Data and assets

- `data/balancing.tres`: every gameplay value (see [balancing.md](balancing.md)).
- `assets/translations/ui.csv`: player-facing texts (en, fr).
- `assets/themes/prototype_theme.tres`: font size for the prototype.

## Data flow of a turn

1. `BoardView` emits `column_tapped(column)`.
2. `GameScreen` checks `GameSession.can_play_column()` and calls `play_column()`.
3. `GameSession` drops the tile and its reflection in `BoardState`, then calls `MergeResolver.resolve_chain()`.
4. The resolver merges, applies gravity and repeats; it returns a `ChainResult` (chain length, points, highest level).
5. `GameSession` updates score, highest level and game over, then advances the `TileGenerator`.
6. `GameScreen` redraws the board and HUD from the session state.

## Tests

`tests/` holds GUT tests for the core (`test_*.gd`) and fixtures (`BoardFixture` describes boards as text, `BalancingFixture` builds explicit configs). Tests and GUT are excluded from exports.
