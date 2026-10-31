# 0003 — Art direction

**Status:** accepted (2026-10-27)

## Context

Step 2.2 needs a visual identity readable on a small screen, in sunlight and for colorblind players, cheap to produce and to re-theme later.

## Decision

- **Two free default themes**, picked in the settings: **Paper** (light, default) and **Night** (dark). Shop themes (step 3.2) come on top of them. Colors live in `data/palette_paper.tres` and `data/palette_night.tres` (`ThemePalette`) and cover the whole interface: background, text, panels, buttons, empty cells, axis, tutorial highlight, tiles.
- **Two tile text colors per theme**, one dark and one light (`tile_text_dark`, `tile_text_light`). Each level takes the one with the higher WCAG contrast on its tile (`ThemePalette.pick_tile_text_color()`), picked once per level when `TilePainter` is built, never per frame. Night tiles are all light, so every Night tile keeps the same near-black text (`tests/test_theme_palettes.gd`). Until 2026-10-31 each theme had a single text color; the Paper mockup (`docs/maquettes/`) mixes light and dark tiles, which a single color cannot serve.
- **Tile colors** (OKLCH lightness on three bands, hues spread so neighbors differ in hue and lightness):
  - Text on tile: at least 4.5:1 in both themes (Paper 7.09, Night 5.4), enforced by `tests/test_theme_palettes.gd`.
  - Tile against the board: at least `min_tile_edge_contrast` against the empty cells and the frame (seen over the background), a palette value so it can be tuned without code; 3:1 in both themes, and Night's is fixed by a test. A tile below it gets a thin outline in its relief color, darkened step by step until it reaches the threshold (`TilePainter`, picked once per level; tested). Night tiles all pass without outline; at 3:1 every Paper tile is outlined.
  - Night only, neighbor levels: lightness gap in grayscale ≥ 10 (11.4); CIEDE2000 gap ≥ 12 in normal vision, deuteranopia, protanopia and tritanopia (13.3).
  - Night limit: with a single text color, the theme only spans about 30 lightness points, so some **non-neighbor** pairs look alike with color vision deficiency (4/256, 16/64, 64/4096 with deuteranopia and protanopia, 2/8, 4/128, 16/4096 with deuteranopia, 2/128, 16/1024, 32/2048 with tritanopia). The value on the tile tells them apart; the pairs are kept in [balancing.md](../balancing.md) for a possible high-contrast mode.
- **Night tile colors** (2026-10-31): levels 1 to 5 come from the visual reference in `docs/maquettes/` (2 turquoise, 4 orchid, 8 off-white, 32 coral pink), except 16, a slightly deeper yellow (`#f8c940` instead of `#fcd24a`) to keep the grayscale gap with 8 (8.7 → 11.4). Levels 6 to 12 keep the former hues, more saturated in the same style.
- **Paper tile colors** (2026-10-31, replaced the same day): the face colors of the "normal" row of `docs/maquettes/couleur_tuiles.png`, sampled as the median of each tile's sides, without its gradient or highlight. All pastel, so every tile takes the dark text.

  | Level | Value | Color | | Level | Value | Color |
  |---|---|---|---|---|---|---|
  | 1 | 2 | `#9cc7fd` | | 7 | 128 | `#f7a4c1` |
  | 2 | 4 | `#8ee4e7` | | 8 | 256 | `#bba7f8` |
  | 3 | 8 | `#95cd95` | | 9 | 512 | `#97c2fc` |
  | 4 | 16 | `#f3dd87` | | 10 | 1024 | `#9ce6e7` |
  | 5 | 32 | `#fbb273` | | 11 | 2048 | `#ebc96b` |
  | 6 | 64 | `#f2dec8` | | 12 | 4096 | `#f8f4ee` |

  A design choice: Paper has no color vision deficiency mode, so the grayscale, CIEDE2000 and confusable-pair rules above do not apply to it. Their figures for the record: grayscale gaps down to 3.3 (128/256), CIEDE2000 down to 2.6 (256/512, deuteranopia). Even in normal vision, 2/512 (ΔE 1.3) and 4/1024 (ΔE 1.8) look almost the same: only the value tells them apart.
- **Font: Fredoka** (SemiBold for the interface, Bold for tile values), one family for the whole game. Chosen over Rubik for its compact digits: "4096" is 2.16 em wide in Fredoka Bold against 2.66 em in Rubik Bold, so it is drawn about 23 % larger in the same tile. It lacks "≈": avoid it in texts.
- **Tile value size** follows `data/tile_text.tres`: as large as possible within a height ratio and a width ratio of the tile, measured with the font, so longer values shrink without per-length cases.
- **Home logo** (2026-10-31): drawn in code by `LogoMark` with the palette `logo_*` colors, no image, so every shop theme gets it from its palette. The circle overlap shows only through the transparency of the fills. The Night glow is thin concentric rings (no blur, no visible steps).
- **Home title**: a Fredoka Bold `Label`; its glow in Night is a widened label shadow, like the HUD values. The white to blue gradient of the Night mockup title is not reproduced (a label has one color, as for the HUD capsule gradient).
- **Interface icons**: Phosphor (MIT), the `fill` and `bold` weights matching the mockups' filled shapes; only the SVGs used are copied, filled in white and tinted with palette colors. Continue shows a resume arrow (`arrow-counter-clockwise`) instead of the mockup's bars, which read as statistics.
- **Not reproduced on the home screen**: the gradients of the buttons, badges and circles, and the paper grain; the style stays flat.
- **Tiles show only their value**, centered. A theme is only a palette.
- **Backgrounds**: one image per theme (`ThemePalette.background_image`), generated with ChatGPT then picked among variants: calm, low-contrast center close to the palette background color, soft mirrored shapes near the top and bottom. Shown scaled to cover the screen, so taller or wider screens crop the edges.
- **Tile base**: a `StyleBoxFlat` drawn by `TilePainter`, no image asset. Rounded corners and a darker bottom border as relief, both relative to the shorter side of the cell; like a 9-slice, corners keep their shape on stretched cells. The relief color is the tile color darkened, so it follows any palette.
- No automatic theme following the system for now. Godot 4.7 has `DisplayServer.is_dark_mode()`; its Android support is still to check. The launch log that reported it was removed with the other debug tools in step 3.1.

## Abandoned: level symbols

Symbols on tiles (circle, triangle, cross, star) were drawn for four levels and rendered next to the value, above it or in a corner. They made tiles look busy, and above the value they shrank the digits by about 25 %. The value already carries the level, as in other games of the genre, so tiles show only the value. Color vision deficiency support is left for phase 3 (for example a high-contrast palette).

## Consequences

- Both themes were validated on a phone (Night indoors, Paper near a window). The Paper tile colors of 2026-10-31 are not tested on a phone yet.
- A shop theme with textures (pixel art, marble) would need optional textures in `ThemePalette`; not built until such a theme is wanted.
- Until the settings screen (step 3.1), debug builds show a "Theme" button in the HUD to switch themes.
