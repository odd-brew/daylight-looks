# Looks (DaylightUI Plugin)

Looks adds frame styles to [DaylightUI](https://github.com/dayightt/DaylightUI). Colors stay in [Palettes](https://github.com/odd-brew/daylight-palettes), or in Daylight if Palettes is off.

This version is 0.1.0. It adds three frame styles: Lintel, Sill and Stamp. It does not add glow styles or presets yet.

Made for World of Warcraft: Forever. Free, under the MIT license.

## Requirements

DaylightUI, current enough to speak plugin API 1.9. Looks is a plugin. It does nothing on its own.

## Install

1. Copy the `Looks` folder into your game's `Interface/AddOns` folder, so you end up with `Interface/AddOns/Looks`.
2. Start the game, or type `/reload` if it's already running.

A fresh install does not change your frames. No Looks style is selected. Pick one in Daylight's Frame style menu (Unit Frames, on Extras and on the player, target, focus, party and PvP pages).

## Frame styles

| Name | What it does |
| --- | --- |
| Lintel | The name and health number sit on a row above a solid bar. |
| Sill | The name tab stays. Power sits as a thin line under the bar. |
| Stamp | A tight name row and a thin power line, with a small portrait ring. |

Class and reaction colors stay as Daylight paints them.

## Settings

Open Daylight's options and go to **Plugins > Looks**. The page lists the three styles. **Restore** means Restore Daylight look: put Daylight's own frame style back. This version can't switch the style for you, because Daylight doesn't give a plugin a way to do that. Restore, and `/looks lintel`, tell you to use the Frame style menu.

`/looks` tells you which Looks style the player frame is wearing.

- `/looks` with nothing on: `Looks: off. Type /looks lintel, sill, stamp, or off.`
- With Lintel on: `Looks: Lintel is on. Type /looks sill, stamp, or off.`
- `/looks off` is the same hint as Restore.

If Daylight is too old, chat says: `Looks: Daylight UI is missing the settings Looks needs, so no frame or glow styles were added.`

## License

See [LICENSE](LICENSE).
