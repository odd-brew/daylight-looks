# Learning

## 2026-11-22 — ODB-156, no public frame-style setter

Daylight's plugin guide (Frame styles, API 1.8) and `API.lua` `View.AddFrameStyle` (around line 1450) are how a plugin adds a style. The style then shows up in Daylight's own Frame style menus. The saved key is `Plugin:key`, for example `Looks:lintel`.

There is no public call that selects the current style. `API.GetSetting` is documented as read-only, and it is not a frame-style setter. `me.Override` changes a setting only for a while and is not saved. The write that actually picks a style is private: `ns.SetStyle` in `DaylightUI_UnitFrames/Units.lua` (around line 150), which calls `DUI:Set("UnitFrames", path, value)`. The guide says only `DaylightUI.API` is promised.

Looks therefore registers Lintel, Sill and Stamp, and does not call `Set` on UnitFrames. `/looks lintel` says to pick Lintel in the Frame style menu. Restore says to pick Daylight there. `/looks` with no extra word reads the player frame through `API.GetUnitFrame("player")` and `API.Parts`, whose `style` field the guide documents (`"daylight"`, `"ribbon"`, or `"Looks:lintel"`).

Stamp's ring is 0.35. Ribbon's documented ring is 0.56. Sizes are left out so Daylight fills in its own heights. The signed-off mock draws Stamp's bar a little shorter so the picture reads apart from Ribbon. That trim is a picture, not a `sizes` entry, until someone asks for it in the style itself.

## 2026-11-22 — ODB-157, no public glow setter

`View.AddGlowStyle` in `API.lua` (around line 1493) registers a glow. The menu key is `Plugin:key`, for example `Looks:wick`. `draw(g, at, lo, hi, size)` uses `g:Light`, `g:Trail` and `g:Edge`. `lo` and `hi` are the accent ends. Looks passes those through and does not supply its own colour. `Widgets.lua` `drawAdded` already runs the draw in `pcall` and, on an error, draws Circling from then on. Looks does not catch that error itself.

There is no `SetGlowStyle` on the public API. The writes that pick a glow are private: `DUI:Set("general", "buttonGlow", ...)`, Nameplates `targetLight`, and each Cooldown Manager spell's `glowStyle`. `/looks wick` says to pick Wick in the glow menu. Restore says to pick none there, and still says to pick Daylight in the Frame style menu. Neither writes those settings, and neither touches Palettes or the accent.

`/looks` can still see a glow the player already picked. `API.GetSetting` is read-only (`API.lua` around line 901). Looks reads `general.buttonGlow` (main buttons) and `Nameplates.targetLight` (the target outline). A Cooldown Manager spell can wear a different glow per spell, so the status line does not try to name that pick. When a Looks frame and a Looks glow are both on, the line names the frame and leaves both out of the list. Wick, Draught and Latch each use a 2 second lap, matching the signed-off sheet.
