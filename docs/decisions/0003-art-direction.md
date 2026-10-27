# 0003 — Art direction

**Status:** accepted (2026-10-27)

## Context

Step 2.2 needs a visual identity readable on a small screen, in sunlight and for colorblind players, cheap to produce and to re-theme later.

## Decision

- **Two free default themes**, picked in the settings: **Paper** (light, default) and **Night** (dark). Shop themes (step 3.2) come on top of them. Colors live in `data/palette_paper.tres` and `data/palette_night.tres` (`ThemePalette`) and cover the whole interface: background, text, panels, buttons, empty cells, axis, tutorial highlight, tiles.
- **One tile text color per theme**: white on every Paper tile, near-black on every Night tile. Tile symbols (step 2.2, part 2) use the same color.
- **Tile colors** (OKLCH lightness on three bands, hues spread so neighbors differ in hue and lightness):
  - Text on tile: at least 4.5:1 (Paper 4.5, Night 5.4), enforced by `tests/test_theme_palettes.gd`.
  - Neighbor levels: lightness gap in grayscale ≥ 10 (Paper 11.7, Night 15.2); CIEDE2000 gap ≥ 12 in normal vision, deuteranopia, protanopia and tritanopia.
  - Limit: with one text color, each theme only spans about 30 lightness points, so some **non-neighbor** pairs look alike with color vision deficiency (Paper: 4/32, 8/512, 128/1024, and with protanopia 4/4096, 8/2048, 32/4096; Night: 64/4096 with deuteranopia and protanopia, 4/256 with protanopia, 2/128, 4/32, 16/1024, 32/2048 with tritanopia). The level symbols must tell every pair apart without color.
- **Font: Fredoka** (SemiBold for the interface, Bold for tile values), one family for the whole game. Chosen over Rubik for its compact digits: "4096" is 2.16 em wide in Fredoka Bold against 2.66 em in Rubik Bold, so it is drawn about 23 % larger in the same tile. It lacks "≈": avoid it in texts.
- **Tile value size** follows `data/tile_text.tres`: as large as possible within a height ratio and a width ratio of the tile, measured with the font, so longer values shrink without per-length cases.
- **Layered tiles**: neutral base and level symbols tinted by the palette, so a theme is only a palette.
- **Tile base**: a `StyleBoxFlat` drawn by `TilePainter`, no image asset. Rounded corners and a darker bottom border as relief, both relative to the shorter side of the cell; like a 9-slice, corners keep their shape on stretched cells. The relief color is the tile color darkened, so it follows any palette.
- No automatic theme following the system for now. Godot 4.7 has `DisplayServer.is_dark_mode()`; debug builds log it at launch to check Android support.

## Consequences

- Both themes were validated on a phone (Night indoors, Paper near a window). Paper tiles 4, 32, 256 and 2048 stay the darkest; the symbols must separate them.
- A shop theme with textures (pixel art, marble) would need optional textures in `ThemePalette`; not built until such a theme is wanted.
- Until the settings screen (step 3.1), debug builds show a "Theme" button in the HUD to switch themes.
