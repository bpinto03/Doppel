# Mockups

`maquette_night.png` (Night theme) and `maquette_paper.png` (Paper theme) are **AI-generated visual references** for the game screen: HUD, previews, board and the first tile colors. `night_menu.png` and `paper_menu.png` are the same kind of reference for the home screen: logo, title and menu buttons. They are not a technical source of truth: proportions, sizes and colors are approximate, some details contradict each other (the same value in two colors), and their aspect ratio (about 9:19.5) differs from the base resolution (1080×1920). The implemented layout is described in [architecture.md](../architecture.md), the tile colors in [0003](../decisions/0003-art-direction.md).

`couleur_tuiles.png` is the visual reference of the Paper tile colors: only its "normal" row is used, for the flat face colors; the example grid, the color vision simulations and the tile gradients and highlights are illustrations. The values in `data/palette_paper.tres` are the source of truth (listed in [0003](../decisions/0003-art-direction.md)).

Godot skips the whole `docs/` folder (`docs/.gdignore`), so the images are never imported nor exported.
