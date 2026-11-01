# 0003 — Art direction

**Status:** accepted (2026-10-27)

## Context

Step 2.2 needs a visual identity readable on a small screen, in sunlight and for colorblind players, cheap to produce and to re-theme later.

## Decision

- **Two free default themes**, picked in the settings: **Paper** (light, default) and **Night** (dark). Shop themes (step 3.2) come on top of them, as entries of the theme catalog (`data/theme_catalog.tres`, see [0008](0008-themes-and-purchase.md)), which also lists Paper and Night. Colors live in `data/palette_paper.tres` and `data/palette_night.tres` (`ThemePalette`) and cover the whole interface: background, text, panels, buttons, empty cells, axis, tutorial highlight, tiles.
- **Two tile text colors per theme**, one dark and one light (`tile_text_dark`, `tile_text_light`). Each level takes the one with the higher WCAG contrast on its tile (`ThemePalette.pick_tile_text_color()`), picked once per level when `TilePainter` is built, never per frame. Night tiles are all light, so every Night tile keeps the same near-black text (`tests/test_theme_palettes.gd`). Until 2026-10-31 each theme had a single text color; the Paper mockup (`docs/maquettes/`) mixes light and dark tiles, which a single color cannot serve.
- **Tile colors** (OKLCH lightness on three bands, hues spread so neighbors differ in hue and lightness):
  - Text on tile: at least 4.5:1 in both themes (Paper 7.09, Night 5.4), enforced by `tests/test_theme_palettes.gd`.
  - Tile against the board: at least `min_tile_edge_contrast` against the empty cells and the frame (seen over the background), a palette value so it can be tuned without code; 3:1 in both themes, and Night's is fixed by a test. A tile below it gets a thin outline in its relief color, darkened step by step until it reaches the threshold (`TilePainter`, picked once per level; tested). Night tiles all pass without outline; at 3:1 every Paper tile is outlined.
  - Night only, neighbor levels: lightness gap in grayscale ≥ 10 (11.4); CIEDE2000 gap ≥ 12 in normal vision, deuteranopia, protanopia and tritanopia (13.3).
  - Night limit: with a single text color, the theme only spans about 30 lightness points, so some **non-neighbor** pairs look alike with color vision deficiency (4/256, 16/64, 64/4096 with deuteranopia and protanopia, 2/8, 4/128, 16/4096 with deuteranopia, 2/128, 16/1024, 32/2048 with tritanopia). The value on the tile tells them apart; the pairs are kept in [balancing.md](../balancing.md) in case a color vision deficiency mode is considered after launch.
- **Night tile colors** (2026-10-31): levels 1 to 5 come from the visual reference in `docs/maquettes/` (2 turquoise, 4 orchid, 8 off-white, 32 coral pink), except 16, a slightly deeper yellow (`#f8c940` instead of `#fcd24a`) to keep the grayscale gap with 8 (8.7 → 11.4). Levels 6 to 12 keep the former hues, more saturated in the same style.
- **Paper tile colors** (2026-10-31, replaced the same day): the face colors of the "normal" row of `docs/maquettes/paper/couleur_tuiles_paper.png`, sampled as the median of each tile's sides, without its gradient or highlight. All pastel, so every tile takes the dark text.

  | Level | Value | Color | | Level | Value | Color |
  |---|---|---|---|---|---|---|
  | 1 | 2 | `#9cc7fd` | | 7 | 128 | `#f7a4c1` |
  | 2 | 4 | `#8ee4e7` | | 8 | 256 | `#bba7f8` |
  | 3 | 8 | `#95cd95` | | 9 | 512 | `#97c2fc` |
  | 4 | 16 | `#f3dd87` | | 10 | 1024 | `#9ce6e7` |
  | 5 | 32 | `#fbb273` | | 11 | 2048 | `#ebc96b` |
  | 6 | 64 | `#f2dec8` | | 12 | 4096 | `#f8f4ee` |

  A design choice: Paper has no color vision deficiency mode, so the grayscale, CIEDE2000 and confusable-pair rules above do not apply to it. Their figures for the record: grayscale gaps down to 3.3 (128/256), CIEDE2000 down to 2.6 (256/512, deuteranopia). Even in normal vision, 2/512 (ΔE 1.3) and 4/1024 (ΔE 1.8) look almost the same: only the value tells them apart.
- **Neon tile colors** (2026-11-01, shop theme): from the "normal" row of `docs/maquettes/neon/couleur_tuiles_neon.png`, sampled as the median of each tile's sides. Neon follows the Night rules for neighbor levels (grayscale gap ≥ 10, CIEDE2000 ≥ 12 in normal vision, deuteranopia, protanopia and tritanopia) and also keeps its repeated hues apart in normal vision (2/512, 4/1024, 128/2048, 64/256: CIEDE2000 ≥ 12), checked by `tests/test_tile_color_distinction.gd`. The sheet fails 7 of 11 neighbor pairs (256/512 look the same even in normal vision: ΔE 4.3) and the 128 text (4.39:1), so seven levels changed lightness only (OKLab L, hue kept):

  | Level | Value | Sheet | Kept | OKLab L | White on tile | Rim |
  |---|---|---|---|---|---|---|
  | 1 | 2 | `#0166f0` | `#0166f0` | 0 | 5.05 | `#26e5fc` |
  | 2 | 4 | `#01b6c3` | `#01b6c3` | 0 | 2.48 | `#69faf9` |
  | 3 | 8 | `#1fb04b` | `#009d38` | −5.7 | 3.57 | `#a3fbab` |
  | 4 | 16 | `#dba40d` | `#e8b129` | +4.0 | 1.95 | `#fcf646` |
  | 5 | 32 | `#e75817` | `#e75817` | 0 | 3.62 | `#fbd357` |
  | 6 | 64 | `#802ff8` | `#802ff8` | 0 | 5.71 | `#e89efd` |
  | 7 | 128 | `#e104a8` | `#ff5adc` | +11.9 | 2.71 | `#fcabf0` |
  | 8 | 256 | `#5308e8` | `#3600af` | −9.6 | 11.83 | `#e184fd` |
  | 9 | 512 | `#2726df` | `#2f3df1` | +5.0 | 6.87 | `#ada7fd` |
  | 10 | 1024 | `#01aad5` | `#00a0cb` | −2.9 | 3.05 | `#69fbfc` |
  | 11 | 2048 | `#cb02a6` | `#bd0099` | −3.1 | 5.80 | `#fa96f6` |
  | 12 | 4096 | `#1e0c74` | `#1e0c74` | 0 | 15.44 | `#ff3df2` |

  Result: neighbor grayscale gap down to 11.1, CIEDE2000 down to 12.0 in every vision; repeated hues 12.5, 12.1, 21.1 and 16.4. The biggest change is 128, lighter. Each tile has the light rim of the sheet (`tile_rim_colors`, sampled on the sheet), which stands for the tile against the board (at least 5.89:1): it lets 256, 512, 2048 and 4096 stay dark instead of being lightened. The 4096 keeps its dark face with a magenta rim (`#ff3df2`; the sheet rim, `#701ee1`, reaches only 2.42:1). Values are white on every tile, as on the sheet, with a dark outline (`tile_text_outline`, `#0e0c22`, 14 % of the font size, chosen on 2026-11-01): white alone reads only 1.95:1 on 16, 2.48 on 4, 2.71 on 128, 3.05 on 1024, 3.57 on 8 and 3.62 on 32, and tiles dark enough for white text cannot keep the neighbor rules. The 4.5:1 rule is checked between the white and its outline.
- **Neon interface** (2026-11-01): colors from the Neon mockups (`docs/maquettes/neon/`), background `#0e0c22`, the median of the center of `background_neon.png`, where the board sits on a flat area. Gold crown and trophy icons shared with Paper. Optional palette fields filled for Neon only: tile rims, game over values in their row color (amber, pink, cyan) and badges drawn as rings. Not reproduced, as for Night: the gradients (title, HUD capsule, board frame, panel borders, shop buttons outline), one color per home and pause button (Continue takes the Play colors), the close cross of the pause, the glossy highlight of cells and previews, line-art icons, the two-tone tutorial hand, uppercase preview captions and the tiles drawn as outlines only on the game mockups (the color sheet wins). Play again stays green, like Resume.
- **Font: Fredoka** (SemiBold for the interface, Bold for tile values), one family for the whole game. Chosen over Rubik for its compact digits: "4096" is 2.16 em wide in Fredoka Bold against 2.66 em in Rubik Bold, so it is drawn about 23 % larger in the same tile. It lacks "≈": avoid it in texts.
- **Tile value size** follows `data/tile_text.tres`: as large as possible within a height ratio and a width ratio of the tile, measured with the font, so longer values shrink without per-length cases.
- **Home logo** (2026-10-31): drawn in code by `LogoMark` with the palette `logo_*` colors, no image, so every shop theme gets it from its palette. The circle overlap shows only through the transparency of the fills. The Night glow is thin concentric rings (no blur, no visible steps).
- **Home title**: a Fredoka Bold `Label`; its glow in Night is a widened label shadow, like the HUD values. The white to blue gradient of the Night mockup title is not reproduced (a label has one color, as for the HUD capsule gradient).
- **Interface icons**: Phosphor (MIT), the `fill` and `bold` weights matching the mockups' filled shapes; only the SVGs used are copied, filled in white and tinted with palette colors. Continue shows a resume arrow (`arrow-counter-clockwise`) instead of the mockup's bars, which read as statistics.
- **Not reproduced on the home screen**: the gradients of the buttons, badges and circles, and the paper grain; the style stays flat.
- **Pause overlay** (2026-10-31): one structure for both themes, from the pause mockups. A scrim of the palette color over the game (no blur), a `StyleBoxFlat` panel (fill, border, rounded corners, a glow in Night and a soft shadow in Paper), the title between two rules (transparent in Paper), then one button per row with a badge, like the home buttons: Resume in its own colors (green in Paper, glowing turquoise in Night), Menu, Restart and Settings in a shared secondary style (violet in Night). The settings page keeps the same panel and title, and its Back button takes the secondary style. Differences from the mockups: no close cross (Resume and the back button close the pause), no subtitle, badges in Night too, text left-aligned in both themes; the panel gradient and swirls are not reproduced.
- **Game over overlay** (2026-10-31): the pause style (scrim, panel, Play again in the Resume colors, Menu in the secondary style), with a smaller title and no rules. Above the panel, straddling its top edge, the palette crown shown large, with a halo drawn in code (a soft disc and thin rays, one palette color). Three stat rows (score, record, highest tile), each in its own tint, with a border and a glow in Night. The crown, its halo and one confetti burst in the tile colors show at every game over, not only on a record; a new record (as `GameOverSummary` decides) throws a larger burst and keeps the "New record!" message. The halo is the one looping animation of the screen (asked for on 2026-10-31, to make the screen livelier): its rays turn slowly and it breathes, by tweening its rotation and opacity, so the drawing is never redone per frame; it stops when the panel hides. Not reproduced: the glossy 3D crown, the pill-shaped buttons, centered text, the blue Play again of Paper and the gradient of the Night panel border.
- **Tutorial panel** (2026-10-31): from the tutorial mockups, only the panel under the board. The modal card style with less padding, the Phosphor `hand-tap` icon (regular, as in the mockups' outlined hand) tinted with `tutorial_icon` beside the instruction, the text centered in the modal text color, and `IconActionButton`s: Next (`arrow-right-bold`) and Done (`check-bold`) in the primary modal style. Skip (`skip-forward-fill`) is deliberately secondary, unlike the mockups' large highlighted button: the expected action is to tap the column. It hides on the last explanation, where Done does the same. Not reproduced: the two-tone icon (yellow rays in Paper), the panel gradient and the pill-shaped button.
- **Tiles show only their value**, centered. A theme is only a palette.
- **Backgrounds**: one image per theme (`ThemePalette.background_image`), generated with ChatGPT then picked among variants: calm, low-contrast center close to the palette background color, soft mirrored shapes near the top and bottom. Shown scaled to cover the screen, so taller or wider screens crop the edges.
- **Tile base**: a `StyleBoxFlat` drawn by `TilePainter`, no image asset. Rounded corners and a darker bottom border as relief, both relative to the shorter side of the cell; like a 9-slice, corners keep their shape on stretched cells. The relief color is the tile color darkened, so it follows any palette.
- No automatic theme following the system for now. Godot 4.7 has `DisplayServer.is_dark_mode()`; its Android support is still to check. The launch log that reported it was removed with the other debug tools in step 3.1.

## Abandoned: level symbols

Symbols on tiles (circle, triangle, cross, star) were drawn for four levels and rendered next to the value, above it or in a corner. They made tiles look busy, and above the value they shrank the digits by about 25 %. The value already carries the level, as in other games of the genre, so tiles show only the value. No color vision deficiency mode either (see below).

## No color vision deficiency mode in the MVP

Decided on 2026-10-31: no color vision deficiency mode (such as a global high-contrast palette) in the MVP. Every tile shows its value, which is enough to tell the levels apart even when two colors look alike. The confusable Night pairs stay listed in [balancing.md](../balancing.md) in case a mode is considered after launch.

## Consequences

- Neon is not tested on a phone yet.
- Both themes were validated on a phone (Night indoors, Paper near a window). The Paper tile colors of 2026-10-31 are not tested on a phone yet.
- A palette may draw a grain overlay over its surfaces and tiles (`surface_grain`, Wood only, see [0009](0009-wood-theme.md)). Other textures (pixel art, marble) are not built until such a theme is wanted.
- Until the settings screen (step 3.1), debug builds show a "Theme" button in the HUD to switch themes.
