# Mockups

**AI-generated visual references**, one folder per theme. They are not a technical source of truth: proportions, sizes and colors are approximate, some details contradict each other (the same value in two colors), and their aspect ratio (about 9:19.5) differs from the base resolution (1080×1920). The implemented layout is described in [architecture.md](../architecture.md), the tile colors in [0003](../decisions/0003-art-direction.md).

| Screen | `paper/` | `night/` | `neon/` | `wood/` |
|--------|----------|----------|---------|---------|
| Game: HUD, previews, board | `jeu_paper.png` | `maquette_night.png` | `jeu_neon.png` | `jeu_wood.png` |
| Home: logo, title, menu buttons | `paper_menu.png` | `night_menu.png` | `neon_menu.png` | `wood_menu.png` |
| Pause overlay | `paper_pause.png` | `night_pause.png` | `neon_pause.png` | `wood_pause.png` |
| Game over overlay | `paper_end.png` | `night_end.png` | `neon_end.png` | `wood_end.png` |
| Tutorial panel under the board (only the panel is a reference) | `paper_tuto.png` | `night_tuto.png` | `neon_tuto.png` | `wood_tuto.png` |
| Theme shop (`ShopScreen`) | `theme_catalog_paper.png` | `theme_catalog_night.png` | `theme_catalog_neon.png` | `theme_catalog_wood.png` |
| Tile colors | `couleur_tuiles_paper.png` | `couleur_tuiles_night.png` | `couleur_tuiles_neon.png` | `couleur_tuiles_wood.png` |

Tile color sheets: only the "normal" row is used, for the flat face colors, sampled as the median of each tile's sides; the example grid, the text at the top and the tile gradients and highlights are illustrations. The Paper sheet is the source of the Paper tile colors. The Night sheet is an illustration only: the Night tile colors were chosen before it (see 0003). The palettes in `data/` are the source of truth.

Godot skips the whole `docs/` folder (`docs/.gdignore`), so the images are never imported nor exported.

## Theme shop: assumed differences

- The equipped card shows the check badge with the accent border and a disabled "Equipped" button. The mockups put the badge on a card whose button still reads "Equip".
- Each card previews its theme in that theme's own palette (frame and tiles), never in the active one.
- Back uses the existing `HomePrimaryButton` variation of `IconActionButton` (round badge with the back arrow, chevron on the right), not the bare left chevron of the mockups.
- Equip and Buy are darker than on the mockups, so their white text reaches 4.5:1: Equip by 22 % (Paper) and 24 % (Night), Buy by 28 % (Paper) and 29 % (Night).

## Neon: assumed differences

Listed in [0003](../decisions/0003-art-direction.md): tile colors retouched for neighbor distinction, white values with a dark outline, no gradients, one color per kind of button (Continue like Play, every pause button but Resume alike), no close cross, no glossy highlight, existing icons, Play again green like Resume. The elements the Neon mockups leave out (Themes button, coin counters, coins earned, pause settings page, combo, placement ghost) are drawn with the Neon palette.

## Wood: assumed differences

Listed in [0009](../decisions/0009-wood-theme.md): one shared grain overlay instead of per-element wood, no glossy relief, hollow cells, engraved HUD icons and titles drawn in code, four tiles lightened for their text, every tile outlined against the brown board, leaves only in the background, no screws, arched sign or arched game over panel, no pause close cross, one color per kind of button, the game board in the tutorial, and the brown preview ring around every shop preview while each preview keeps its own theme colors.
