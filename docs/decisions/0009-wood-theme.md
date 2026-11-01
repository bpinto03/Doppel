# 0009 — Wood theme

**Status:** accepted (2026-11-01, wood grain and engraving added the same day)

## Context

The shop needs more themes than Neon (step 3.2, target 4 to 6). The Wood mockups (`docs/maquettes/wood/`) show a warm wood look with grain, hollow cells, engraved icons and title, leaves, screws and glossy relief. A theme stays a palette plus a catalog entry ([0008](0008-themes-and-purchase.md)). The first version was flat colors; the grain and the engraved look were asked for next, with their rendering cost measured (the tile glow alone already cost +28 % primitives in Compatibility).

## Decision

- **Wood** (`wood`) joins the catalog after Neon, at 500 coins **[TO TEST]**, with `data/palette_wood.tres` and `assets/backgrounds/background_wood.png`, supplied without interface, leaves in the corners. The leaves live only in that image: no decoration control, no leaf on any panel, no leaf asset.
- **Grain**: one overlay, `assets/textures/wood_grain_overlay.png`, built by `tools/textures/build_grain_overlay.gd` from a grayscale grain picture (`_sources/textures/wood_grain.png`, kept out of the build): black where the grain is darker than its mean, white where it is lighter, the gap in alpha, clamped at 3 standard deviations; 1024 px, cropped from the center. Drawn by `SurfaceGrain` inside the rounded corners of each surface, at its own pixel size, from a region picked by the surface position, never repeated (the picture is not seamless). Palette fields, all optional and off by default: `surface_grain`, `surface_grain_opacity` (0.16: every opaque interface box through `GrainStyleBox`, the board frame, the empty cells) and `tile_grain_opacity` (0.08). At an opacity, the grain darkens a color toward black or lightens it toward white by at most that opacity, so every tested text keeps 4.5:1 at both extremes (`tests/test_theme_palettes.gd`). Translucent boxes (scrim, preview frames, ring) stay flat.
- **Hollow cells**: `cell_inset_shadow` (a soft shadow under the top edge, blended into the cell) and `cell_inset_highlight` (a light lip along the bottom edge) replace the cell outline. Light comes from above, as on `jeu_wood.png`.
- **Engraved HUD icons**: `hud_icon_engraving` and `hud_icon_engraving_highlight`. The crown and trophy keep their textures but are drawn as dark brown silhouettes over a light lip 3 px lower (`assets/shaders/engraved_icon.gdshader`, one draw per icon). The game over panel keeps the gold icons, as on `wood_end.png`.
- **Engraved titles**: `title_engraving_highlight`. The home and modal titles drop a light lip 4 px under their letters (the label shadow, offset instead of widened). No grain inside the letters, which would need a shader per label.
- **Tile colors**: the "normal" row of `couleur_tuiles_wood.png`, sampled as the median of each tile's sides; the sheet wins over the tile colors of the other mockups. Text colors near the sheet's: dark `#140802`, light `#ffe8c8`; each level takes the one with the higher contrast (0003). Four tiles were lightened in OKLab L, hue kept, so their dark values keep 4.5:1 on the darkest and lightest grain, as on the sheet:

  | Value | Sheet | Kept | OKLab L | Text | Contrast | On grain |
  |---|---|---|---|---|---|---|
  | 2 | `#d2aa7c` | `#d2aa7c` | 0 | dark | 9.18 | 7.79 |
  | 4 | `#867f4c` | `#8c8552` | +2.0 | dark | 5.25 | 4.54 |
  | 8 | `#605231` | `#605231` | 0 | light | 6.41 | 5.20 |
  | 16 | `#ca8a46` | `#ca8a46` | 0 | dark | 6.79 | 5.81 |
  | 32 | `#b45a23` | `#c76c37` | +5.8 | dark | 5.28 | 4.56 |
  | 64 | `#c38d55` | `#c38d55` | 0 | dark | 6.82 | 5.83 |
  | 128 | `#a25645` | `#be6f5d` | +8.5 | dark | 5.28 | 4.56 |
  | 256 | `#69403d` | `#69403d` | 0 | light | 7.34 | 5.90 |
  | 512 | `#4b2e1d` | `#4b2e1d` | 0 | light | 10.32 | 8.11 |
  | 1024 | `#895025` | `#895025` | 0 | light | 5.44 | 4.54 |
  | 2048 | `#aa5d20` | `#bf7136` | +6.5 | dark | 5.29 | 4.57 |
  | 4096 | `#512b10` | `#512b10` | 0 | light | 10.35 | 8.18 |

  The sheet draws dark values on 8, 256 and 1024, where they would not reach 4.5:1: those take the light text. Darker text colors were picked over larger tile changes: with the first text colors (`#2a1608`, `#fcd8a9`), grain at 0.08 would have needed up to +12 points and made 16 and 32 the same with deuteranopia.
- **No neighbor or color vision rules**, as for Paper (0003): only the value tells levels apart. Measured for the record: neighbor grayscale gap down to 7.4 (16/32), CIEDE2000 down to 11.1 in normal vision (256/512), 5.7 with deuteranopia, 8.6 with protanopia, 7.8 with tritanopia. Close pairs, kept in [balancing.md](../balancing.md): 16/64 (ΔE 2.9, almost the same), 32/2048 (3.6) and 512/4096 (4.4) even in normal vision. 4/8, suspected on the sheet, is not close (ΔE 19.5).
- **Tile against the board**: `min_tile_edge_contrast` stays 3.0, as in every theme. The brown cells (`#946030`) and frame (`#ba7a40`) give the tiles only 1.07:1 to 3.49:1, so all twelve tiles are outlined in their relief color darkened until 3:1 (`TilePainter`), which reads like the dark tile edges of the mockups.
- **Interface**: colors sampled on the mockups. Background `#b07643`, the median of the center of `background_wood.png`. Dark brown Play and Continue, light wood Tutorial, Settings and secondary modal buttons, one green for Resume and Play again. Fills darkened so their light text keeps 4.5:1 on grain: Resume and Play again `#525a2f` with `#fff6e6` text (mockup `#596236`), Buy `#30500f` and its highlight `#395c16`, Equip highlight `#83421e`; the coins earned text is `#451f00`. The HUD score and record panels are transparent, so only the capsule is grained. Tutorial highlights stay yellow (`#ffd43b`). Soft dark shadows where the mockups show some, a yellow glow on the equipped shop card; no other glow, `tile_glow_opacity` 0. Gold crown and trophy textures shared with Paper.
- **Shop previews**: the optional ring of the active palette (`shop_preview_ring`, `shop_preview_ring_width`, none by default) draws the thick brown frame of `theme_catalog_wood.png` around every preview, 16 px at the base resolution, while each preview keeps its own theme colors inside.
- **Not reproduced**: screws and rivets, leaves on panels, the arched "Themes" sign, the arched game over panel (the `ModalCard` rectangle of the other themes, crown straddling its top edge), the pause close cross, one color per button (Continue takes the Play colors), glossy relief, grain inside the title letters, line-art icons, the two-tone tutorial hand, the light tutorial cells with dark outer columns (the tutorial board is the game board), the duplicated and inconsistent Paper and Night cards of the shop mockup.

## Consequences

- Paper, Night and Neon are unchanged: every new field is off unless a palette sets it, they keep plain `StyleBoxFlat` boxes, and `test_theme_snapshots.gd` stays green.
- Rendering cost, full board (36 tiles) at 1080×2340 in Compatibility: draw calls 99 to 141 (+42 %), primitives 14,970 to 16,062 (+7 %), objects 183 to 225; Wood without grain costs the same as Paper. Each grained surface is one more draw call, since its texture breaks the batch. If the frame rate drops, set `tile_grain_opacity` to 0 first (the 36 board tiles and 3 previews make most of the 42 calls); drawing every tile grain in one pass, between the tile boxes and the values, could also bring them back into a few batches (not tried).
- The grain picture is not seamless: a surface larger than 1024 px stretches the overlay slightly instead of repeating it.
- The background is scaled to cover the screen. Its leaves reach 102 px from the top and start 254 px from the bottom of an 852 × 1846 image: whole on 19.5:9 and 20:9 screens, only the tips at the top on 18:9 (71 px cropped), none at the top and about a third at the bottom on 16:9 (166 px cropped). The image is slightly translucent (alpha 227 to 248), so the palette background, close to its center color, shows through a little.
- Wood is not tested on a phone yet.
