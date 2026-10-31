# Mockups

`maquette_night.png` (Night theme) and `maquette_paper.png` (Paper theme) are **AI-generated visual references** for the game screen: HUD, previews, board and the first tile colors. They are not a technical source of truth: proportions, sizes and colors are approximate, some details contradict each other (the same value in two colors), and their aspect ratio (about 9:19.5) differs from the base resolution (1080×1920). The implemented layout is described in [architecture.md](../architecture.md), the tile colors in [0003](../decisions/0003-art-direction.md).

Godot skips the whole `docs/` folder (`docs/.gdignore`), so the images are never imported nor exported.
