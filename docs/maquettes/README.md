# Mockups

`maquette_night.png` (Night theme) and `maquette_paper.png` (Paper theme) are **AI-generated visual references** for the game screen: HUD, previews, board and the first tile colors. `night_menu.png` and `paper_menu.png` are the same kind of reference for the home screen: logo, title and menu buttons, `night_pause.png` and `paper_pause.png` for the pause overlay, `night_end.png` and `paper_end.png` for the game over overlay, `night_tuto.png` and `paper_tuto.png` for the tutorial panel under the board (only the panel is a reference there), and `night/theme_catalog_night.png` and `paper/theme_catalog_paper.png` for the theme shop (`ShopScreen`). They are not a technical source of truth: proportions, sizes and colors are approximate, some details contradict each other (the same value in two colors), and their aspect ratio (about 9:19.5) differs from the base resolution (1080×1920). The implemented layout is described in [architecture.md](../architecture.md), the tile colors in [0003](../decisions/0003-art-direction.md).

`couleur_tuiles.png` is the visual reference of the Paper tile colors: only its "normal" row is used, for the flat face colors; the example grid, the color vision simulations and the tile gradients and highlights are illustrations. The values in `data/palette_paper.tres` are the source of truth (listed in [0003](../decisions/0003-art-direction.md)).

Godot skips the whole `docs/` folder (`docs/.gdignore`), so the images are never imported nor exported.

## Theme shop: assumed differences

- The equipped card shows the check badge with the accent border and a disabled "Equipped" button. The mockups put the badge on a card whose button still reads "Equip".
- Each card previews its theme in that theme's own palette (frame and tiles), never in the active one.
- Back uses the existing `HomePrimaryButton` variation of `IconActionButton` (round badge with the back arrow, chevron on the right), not the bare left chevron of the mockups.
- Equip and Buy are darker than on the mockups, so their white text reaches 4.5:1: Equip by 22 % (Paper) and 24 % (Night), Buy by 28 % (Paper) and 29 % (Night).
