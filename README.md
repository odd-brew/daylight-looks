# Looks (DaylightUI Plugin)

Add frame styles and glow styles to Daylight. Colors stay in Palettes for DaylightUI, or in Daylight if Palettes for DaylightUI is off.

This version is 0.2.0. It adds three frame styles (Lintel, Sill and Stamp) and three glow styles (Wick, Draught and Latch). It does not add presets yet.

Made for World of Warcraft: Forever. Free, under the MIT license.

## Requirements

DaylightUI, current enough to speak plugin API 1.9. Looks is a plugin. It does nothing on its own.

## Install

1. Copy the `Looks` folder into your game's `Interface/AddOns` folder, so you end up with `Interface/AddOns/Looks`.
2. Start the game, or type `/reload` if it's already running.

A fresh install does not change your frames or your glow. No Looks style is selected. Pick a frame style in Daylight's Frame style menu (Unit Frames, on Extras and on the player, target, focus, party and PvP pages). Pick a glow in Daylight's glow menu. Looks glows show where Daylight already shows a plugin glow: main-window buttons, the target nameplate outline, and Cooldown Manager spells.

## Frame styles

| Name | What it does |
| --- | --- |
| Lintel | The name and health number sit on a row above a solid bar. |
| Sill | The name tab stays. Power sits as a thin line under the bar. |
| Stamp | A tight name row and a thin power line, with a small portrait ring. |

Class and reaction colors stay as Daylight paints them.

## Glow styles

Wick, Draught and Latch use the accent you already have. They do not set a glow colour of their own.

| Name | What it does |
| --- | --- |
| Wick | Light gathers at the corners, one turn about every 2 seconds. |
| Draught | A wash along the top edge. |
| Latch | A short catch of light around the edge, then still. |

## Settings

Open Daylight's options and go to **Plugins > Looks**. The page lists the frame styles and the glow styles. **Restore** means Restore Daylight look: put Daylight's own frame style back, and take Looks glows off. This version can't switch either one for you, because Daylight doesn't give a plugin a way to do that. `/looks lintel` tells you to use the Frame style menu. `/looks wick` tells you to use the glow menu.

`/looks` tells you which Looks style is on.

- `/looks` with nothing on: `Looks: off. Type /looks lintel, sill, stamp, wick, draught, latch, or off.`
- With Lintel on: `Looks: Lintel is on. Type /looks sill, stamp, wick, draught, latch, or off.`
- With Wick on: `Looks: Wick is on. Type /looks lintel, sill, stamp, draught, latch, or off.`
- `/looks off` is the same hint as Restore.

If Daylight is too old, chat says: `Looks: Daylight UI is missing the settings Looks needs, so no frame or glow styles were added.`

## License

See [LICENSE](LICENSE).
