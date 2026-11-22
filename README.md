# Looks (DaylightUI Plugin)

Add frame styles and glow styles to Daylight. Colors stay in Palettes for DaylightUI, or in Daylight if Palettes for DaylightUI is off.

This version is 0.2.0. It adds frame styles (Lintel, Sill, Stamp, Trestle, Flagon, Signboard and Trough), three glow styles (Wick, Draught and Latch), and five presets.

Made for World of Warcraft: Forever. Free, under the MIT license.

## Requirements

DaylightUI, current enough to speak plugin API 1.9. Looks is a plugin. It does nothing on its own.

## Install

1. Copy the `Looks` folder into your game's `Interface/AddOns` folder, so you end up with `Interface/AddOns/Looks`.
2. Start the game, or type `/reload` if it's already running.

A fresh install does not change your frames or your glow. No Looks style is selected until you pick one. Looks glows show where Daylight already shows a plugin glow: main-window buttons and the target nameplate outline. A Cooldown Manager spell keeps the glow you set on that spell.

## Frame styles

| Name | What it does |
| --- | --- |
| Lintel | The name and health number sit on a row above a solid bar. |
| Sill | The name tab stays. Power sits as a thin line under the bar. |
| Stamp | A tight name row and a thin power line, with a small portrait ring. |
| Trestle | A full portrait on a named board. Power hangs as a rail. The ring stays full size. |
| Flagon | The name sits on a row over a tall bar, with a small portrait ring. |
| Signboard | A tall name board over a hairline bar. The ring is as large as the stack. |
| Trough | A short health bar, with a taller power line under it. The ring is as large as the stack. |

Class and reaction colors stay as Daylight paints them.

## Glow styles

Wick, Draught and Latch use the accent you already have. They do not set a glow colour of their own.

| Name | What it does |
| --- | --- |
| Wick | Light gathers at the corners, one turn about every 2 seconds. |
| Draught | A wash along the top edge. |
| Latch | A short catch of light around the edge, then still. |

## Settings

Open Daylight's options and go to **Plugins > Looks**. The page is one Presets & Styles card. On the left, each preset shows its name, a pair such as Lintel + Wick, the mood line and Apply. On the right, frame styles and glow styles each have a select box, a small icon, the name, the description and the key. The current pick is highlighted and shows [On]. The note at the top right says it starts off on first login. Restore Daylight look is in the header and the footer. The first time Looks changes a style, it remembers the frame style, main-button glow and target outline light it found. Restore puts those back. If Looks has not changed them yet, Restore uses Daylight's own defaults.

Clicking a select box, Apply, or `/looks lintel` applies that pick. `/looks hearthnight` applies Lintel and Wick. Harvestide is Sill and Draught, Tidemark is Stamp and Draught, Old Road is Lintel and Latch, Vigil is Sill and Wick. A preset does not change Palettes or the accent. If Daylight cannot take the write, chat tells you which menu to use, and nothing errors.

`/looks` tells you which Looks style is on. The list is the frame styles, then the glows, then the presets, and it leaves out whatever is already on.

- `/looks` with nothing on: `Looks: off. Type /looks lintel, sill, stamp, trestle, flagon, signboard, trough, wick, draught, latch, hearthnight, harvestide, tidemark, oldroad, vigil, or off.`
- `/looks off` is the same hint as Restore.

If Daylight is too old, chat says: `Looks: Daylight UI is missing the settings Looks needs, so no frame or glow styles were added.`

## License

See [LICENSE](LICENSE).
