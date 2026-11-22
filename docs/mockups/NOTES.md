<!-- looks-v1 -->
# Looks (DaylightUI Plugin) — Design Notes (22 November 2026)

These are preview screenshots, not in-game. In-game rendering, fonts, scaling and textures were not checked. Nothing goes to Gate, Tinker, or Herald until Mike approves these sheets.

## Architecture & Boundary with Palettes for DaylightUI

- **Two plugins, two layers:** **Palettes for DaylightUI** owns color (`background`, `band`, `accent`, window tint, ink). **Looks** owns shape and motion (`AddFrameStyle`, `AddGlowStyle`, and seasonal frame+glow presets only). Looks has no glow-colour override.
- **Starts off:** first login leaves Daylight's default frame style and glow untouched.
- **Presets:** apply only a `frame + glow` pair; they never enable Palettes for DaylightUI, change `accent`/`windowTint`, or touch class/reaction/health/power fills. Listed in this order on sheet 06:
  1. **Hearthnight** — Lintel + Wick. "A winter hearth: a named beam, a quiet corner flame. Sits well with Palettes for DaylightUI — Ember."
  2. **Harvestide** — Sill + Draught. "Harvest light along the sill of the bar. Sits well with Palettes for DaylightUI — Vanilla."
  3. **Tidemark** — Stamp + Draught. "A tight line at the waterline, a soft wash along the rim. Sits well with Palettes for DaylightUI — Tide."
  4. **Old Road** — Lintel + Latch. "A weathered beam and a short catch of lantern light. Sits well with Palettes for DaylightUI — Forever."
  5. **Vigil** — Sill + Wick. "The name tab stays, and a flame is kept lit at the corners. Sits well with Palettes for DaylightUI — Paladin."
- **Naming rule (Mike, 22 Nov 2026, 8:37 AM ET):** wherever a mockup references a Palettes theme, name the plugin and the theme in full: **Palettes for DaylightUI — Ember** (or Vanilla, Forever). Never a bare theme name or a bare "Palettes". Assume Looks users may not know about Palettes for DaylightUI. In-UI text wraps at body size (11.5px); it is not shrunk to fit.
- **Glow colour hint (Pitch, confirmed; used verbatim on sheets 05 and 06):** "Glow colour follows your accent colour. Change it in Daylight's accent setting, or with Palettes for DaylightUI." Do not name a menu path. Daylight's own accent setting can be used without Palettes for DaylightUI.
- **No Blizzard / copied art:** unit portrait emblems, action spell icons, rail glyphs, and glow overlays are original geometric SVGs.

## Key Hexes & Measurements

- **Daylight default baseline (Sheets 01–06):**
  - `window` / `bg`: `#141417`, `border`: `#060607`, `band`: `#1A1711`, `bandLit`: `#332F24`
  - `title`: `#FFFFFF`, `text`: `#F2EEE6`, `label`: `#C2B59E`, `off`: `#8C8273`
  - Default accent gradient (`glow_lo` → `glow_hi`): `#1E90FF` → `#A25EC7` (stop 3 `#E65A72`)
  - Suggested plugin rail/highlight tint (`looks-pack-spec.md`): `#C4A574` (muted brass)
- **Red UI action buttons (standing rule):** fill `#7A2A22` → `#4A1410`, edge `#9A3C32`, ink `#F6E6D8`. `‹ Back` sits bottom-left on Options *sub-pages* (`04`, `05`). **Plugins > Looks** (`06`) is a top-level page like Plugins > Palettes, so it has no Back. Sheet `07` keeps a decorative Back only inside the together-shot chrome, not as a page control.
- **Palettes for DaylightUI — Ember (Sheet 07 together shot):** `window` `#18120E`, `bg` `#211812`, `band` `#2A1F16`, `band_lit` `#4A3524`, `accent` / `glow_lo` `#E8A04A`, `glow_hi` `#F3D59A`, `text` `#F4E8D8`, `label` `#D0BA9F`.
- **Native game colors (kept unmodified):** Warrior `#C69B6D`, Rage `#C41F3B`, Hostile `#E63333`, Mana `#0070DD`.
- **Frame piece proportions in mock:**
  - `Daylight`: name tab + inner power bar + `42px` full ring (`38px` in compact strip).
  - `Ribbon`: `ring = 0.56` (`26px` / `23px` compact), shown with Daylight's standard tab and inner power bar.
  - `Looks:lintel`: `row = true`, `line = false`, full ring (`42px` / `38px`).
  - `Looks:sill`: `row = false` (name tab kept), `line = true` (`4px` hung sill below bar), full ring (`42px` / `38px`).
  - `Looks:stamp`: `row = true`, `line = true`, `ring = 0.35` (`18px` / `16px` compact), trimmed `20px` bar height so it separates cleanly from Ribbon's `0.56`.

## Contrast Audit

| Pair | Foreground | Background | Ratio | Floor | Status |
|---|---|---|---|---|---|
| Daylight title on bg | `#FFFFFF` | `#141417` | 18.39:1 | 4.5:1 | Pass |
| Daylight text on bg | `#F2EEE6` | `#141417` | 15.89:1 | 4.5:1 | Pass |
| Daylight label on bg / band | `#C2B59E` | `#141417` / `#1A1711` | 9.10:1 / 8.85:1 | 4.5:1 | Pass |
| Daylight off on bg | `#8C8273` | `#141417` | 4.86:1 | 4.5:1 | Pass |
| Glow lo `#1E90FF` on bg / band | `#1E90FF` | `#141417` / `#1A1711` | 5.68:1 / 5.52:1 | 3.0:1 | Pass |
| Glow hi `#A25EC7` on bg / band | `#A25EC7` | `#141417` / `#1A1711` | 4.34:1 / 4.22:1 | 3.0:1 | Pass |
| Plugin brass `#C4A574` on bg / band | `#C4A574` | `#141417` / `#1A1711` | 7.86:1 / 7.65:1 | 3.0:1 | Pass |
| Red button ink on fill top / bot | `#F6E6D8` | `#7A2A22` / `#4A1410` | 7.90:1 / 12.32:1 | 4.5:1 | Pass |
| Palettes for DaylightUI — Ember accent `#E8A04A` on that theme's bg | `#E8A04A` | `#211812` | 7.94:1 | 3.0:1 | Pass |
| Palettes for DaylightUI — Ember text on that theme's bg | `#F4E8D8` | `#211812` | 14.44:1 | 4.5:1 | Pass |
| Native Warrior `#C69B6D` on bg / tab | `#C69B6D` | `#141417` / `#1A1711` | 7.28:1 / 7.08:1 | — | Native |
| Native Hostile `#E63333` on bg / tab | `#E63333` | `#141417` / `#1A1711` | 4.28:1 / 4.16:1 | — | Native (with 1px black shadow) |

## Spec vs Brief Conflicts & Unverified Assumptions

1. **Sheet 03 remock (22 Nov 2026, round 1):** `AddGlowStyle` does not reach action bars. Each glow now leads on a red **Accept** button (hero + three-frame motion sequence), with a **Cooldown Manager spell** as the second crop. The earlier action-button hero is withdrawn.
2. **Sheet 06 Back removed (round 1):** Plugins > Looks is a top-level page, like Plugins > Palettes. Red **Apply** (preset rows) and **Restore** stay; `‹ Back` is gone.
3. **Sheet 05 built-in glow labels (round 1):** listed by API key only (`none`, `circle`, `comet`, `breathe`, `twinkle`, `shine`). The confirmed in-game words remain **none** and the error fallback **Circling**.
4. **Sheet 07 (round 1):** Wick moved off the action-bar-looking tile onto a labelled Cooldown Manager spell. The Accept crop and target nameplate outline stay.
5. **Unverified Ribbon pieces (Sheet 02, unchanged):** `looks-pack-spec.md` verifies Ribbon's `ring = 0.56` only; `row`, `line` and default `sizes` are not a criterion and stay mocked as Daylight's tab + inner bar with the `0.56` ring.

## Files

- `01-frame-styles-player-target.png` — Player and Target frames in Lintel, Sill and Stamp.
- `02-frame-styles-compare.png` — Five-up Player compare strip: Daylight, Ribbon, Lintel, Sill, Stamp.
- `03-glow-styles.png` — Wick, Draught and Latch on a main Accept button (hero + 3-frame motion) with a Cooldown Manager spell as the second crop. Remocked round 1; no action-bar buttons.
- `04-frame-style-menu.png` — Daylight Frame style menu (Unit Frames > Player) with Lintel, Sill and Stamp under Daylight and Ribbon.
- `05-glow-menu.png` — Daylight Glow menu (General & CDM spell Look tab) with Wick, Draught and Latch next to built-ins referred to by key (`none`, `circle`, `comet`, `breathe`, `twinkle`, `shine`). Body-size hint under the picker: "Glow colour follows your accent colour. Change it in Daylight's accent setting, or with Palettes for DaylightUI." No preset mood lines on this sheet.
- `06-plugins-looks-page.png` — Plugins > Looks with five presets (Hearthnight, Harvestide, Tidemark, Old Road, Vigil), frame styles, glow styles, the confirmed glow-colour hint, and Restore Daylight look. No Back button (top-level page). The window is taller so every preset mood line and Restore stay visible at body size.
- `07-together-ember-hearthnight.png` — Palettes for DaylightUI — Ember + Looks — Hearthnight (Lintel + Wick) on Accept, a Cooldown Manager spell, and the target nameplate outline. Caption uses both full names and states these are two separate plugins; Looks did not apply Palettes for DaylightUI — Ember.

## Future ideas (not in the current build)

Ideas only, for a later Looks pass. P1–P3 (Lintel, Sill, Stamp; Wick, Draught, Latch; the five presets) stay as approved and are already building. Sheets 01–07 were not changed. Every name below is a **working name**; naming is Pitch's call. Mike picks, then Pitch specs, before anything is filed or built.

Generator: `src/generate_future_looks.py`. PNGs and HTML: `future/`. Pipeline: HTML/CSS, headless Chrome at device scale 2, same Daylight tokens as sheets 01–06.

### F1 — Frame style ideas

Built only from documented `AddFrameStyle` pieces: `row`, `line`, `ring` (0.3 to 1), and `sizes` (`height`, `powerHeight`, `tabHeight`, spacing). No new shapes (power beside health, a vertical frame). Mocked in Daylight default colours. Native Warrior / Hostile / Rage / Mana fills are unchanged.

| Working name | Pieces | Mood | Why it reads apart |
| --- | --- | --- | --- |
| **Mantel** | `row = true`, no line, ring omitted (full), tall `tabHeight` (~22px name beam), short `height` (~14px bar) | A deep name beam over a shallow firebox. | Same flags as Lintel, flipped proportions: a heavy shelf over a low bar, not a slim beam over a standard bar. The tall row is mocked as a filled shelf so the size change is visible. If Daylight paints every row, Lintel would gain a slim filled beam and Mantel would remain the deep one. |
| **Trestle** | `row = true`, `line = true`, ring omitted (full), ordinary heights, slightly more spacing under the rail | A full portrait on a named board, power hung as a rail. | Stamp's flags at a full ring — the unused combination at Daylight scale. Stamp stays the small-ring version. |
| **Bung** | no row, `line = true`, `ring = 0.30` (API minimum; mocked at 15px vs Stamp's 18px on the same scale) | The name tab stays; a small bung at the cask end, power as a drip underneath. | Sill's flags with the smallest legal ring. Distinct from Stamp (which uses a name row, not a tab) and from Ribbon (`ring = 0.56`, no line). |
| **Flagon** | `row = true`, no line, `ring = 0.35`, tall `height` (~32px bar) | A small boss and a deep cup, the name cut into the lip. | Lintel's flags with Stamp's small ring and a much taller bar, so it reads as a cup, not a beam or a stamp. |

`F1-frame-ideas.png` shows each as a Player and Target frame, plus a compare strip of Daylight, Ribbon, Lintel, Sill and Stamp on one row and the four ideas on the row below.

### F2 — Glow style ideas

Drawn with documented `Light`, `Trail` and `Edge` calls, in Daylight's default accent (`#1E90FF` → `#A25EC7`). Glow colour follows the accent; Looks has no colour override. Shown mid-motion on a red Accept button (a supported main-window surface) with a 3-frame motion strip. These styles would also apply to the target nameplate outline and Cooldown Manager spells. They do **not** apply to action bars.

| Working name | Calls | Motion | Mood | Why it reads apart |
| --- | --- | --- | --- | --- |
| **Cinder** | Light + Trail | Beads fall down both side edges, then go out. | Cinders slip down the sides, then go out. | Not corner pools (Wick), not a top wash (Draught), not a circling spark or comet. |
| **Ripple** | Edge | A single inset ring contracts from the lip toward the centre, then fades. | A quiet ring travels in from the lip, like a ripple in a cup. | A traveling ring, not a whole-button `breathe` pulse and not a rim wash. |
| **Grate** | Edge | A soft wash travels along the bottom lip only. | Warm light lies along the lower lip, like a grate. | The opposite edge from Draught (top rim). No side clasps (Latch), no corner flame (Wick). |
| **Drip** | Light + Trail + Edge | One bead gathers at the top centre, falls, and pools along the bottom. | A single drop gathers, falls, and pools at the bottom. | A vertical mid-line fall, not a `shine` slash, `twinkle`, or Latch clasp. |

Hint used on the sheet (no menu path): "Glow colour follows the accent. These shots use Daylight's default accent. Change it in Daylight's accent setting, or with Palettes for DaylightUI."

### Files

- `future/F1-frame-ideas.png` — four frame-style ideas (Mantel, Trestle, Bung, Flagon) with a compare strip against the five existing styles.
- `future/F2-glow-ideas.png` — four glow-style ideas (Cinder, Ripple, Grate, Drip) on a red Accept button, mid-motion plus a 3-frame strip.
