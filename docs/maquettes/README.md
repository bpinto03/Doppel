# Mockups

**AI-generated visual references**, one folder per theme. They are not a technical source of truth: proportions, sizes and colors are approximate, some details contradict each other (the same value in two colors), and their aspect ratio (about 9:19.5) differs from the base resolution (1080×1920). The implemented layout is described in [architecture.md](../architecture.md), the tile colors in [0003](../decisions/0003-art-direction.md).

| Screen | `paper/` | `night/` | `neon/` |
|--------|----------|----------|---------|
| Game: HUD, previews, board | `jeu_paper.png` | `maquette_night.png` | `jeu_neon.png` |
| Home: logo, title, menu buttons | `paper_menu.png` | `night_menu.png` | `neon_menu.png` |
| Pause overlay | `paper_pause.png` | `night_pause.png` | `neon_pause.png` |
| Game over overlay | `paper_end.png` | `night_end.png` | `neon_end.png` |
| Tutorial panel under the board (only the panel is a reference) | `paper_tuto.png` | `night_tuto.png` | `neon_tuto.png` |
| Theme shop (`ShopScreen`) | `theme_catalog_paper.png` | `theme_catalog_night.png` | `theme_catalog_neon.png` |
| Tile colors | `couleur_tuiles_paper.png` | `couleur_tuiles_night.png` | `couleur_tuiles_neon.png` |

Tile color sheets: only the "normal" row is used, for the flat face colors, sampled as the median of each tile's sides; the example grid, the text at the top and the tile gradients and highlights are illustrations. The Paper sheet is the source of the Paper tile colors. The Night sheet is an illustration only: the Night tile colors were chosen before it (see 0003). The palettes in `data/` are the source of truth.

Godot skips the whole `docs/` folder (`docs/.gdignore`), so the images are never imported nor exported.

## Theme shop: assumed differences

- The equipped card shows the check badge with the accent border and a disabled "Equipped" button. The mockups put the badge on a card whose button still reads "Equip".
- Each card previews its theme in that theme's own palette (frame and tiles), never in the active one.
- Back uses the existing `HomePrimaryButton` variation of `IconActionButton` (round badge with the back arrow, chevron on the right), not the bare left chevron of the mockups.
- Equip and Buy are darker than on the mockups, so their white text reaches 4.5:1: Equip by 22 % (Paper) and 24 % (Night), Buy by 28 % (Paper) and 29 % (Night).
