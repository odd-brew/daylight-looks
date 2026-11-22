# Changelog

## [0.2.0] - 2026-11-22

### Added
- Glow styles (ODB-157): Wick, Draught and Latch, in Daylight's glow menus and on Plugins > Looks. They sit beside Daylight's built-in glows. Glow colour follows the accent.
- Frame styles (ODB-159): Trestle, Flagon, Signboard and Trough, with Lintel, Sill and Stamp. Trough's power line is taller than its health bar. Daylight does not clamp that line, so Trough ships.
- Presets (ODB-158): Hearthnight, Harvestide, Tidemark, Old Road and Vigil. Each is one frame style and one glow. A preset does not change Palettes or the accent.
- Select and apply on Plugins > Looks. The page is a Presets & Styles card: pair chips and Apply on the left, and on the right a select box, a drawn icon, the name, the description and the key. The current pick is highlighted and marked [On]. `/looks lintel`, `/looks wick` and `/looks hearthnight` use the same apply path. If Daylight cannot take the write, chat names the menu and nothing errors.
- Restore puts back the frame style, the main-button glow and the target outline light from before Looks first changed them. That snapshot is saved in LooksDB, so a reload still has it, and a successful Restore clears it. If Looks has not changed them, Restore uses Daylight's own defaults. Restore is in the header and the footer.

## [0.1.0] - 2026-11-22

### Added
- Looks (DaylightUI Plugin) for World of Warcraft: Forever. It starts off. A fresh install does not change your frames.
- Three frame styles in Daylight's Frame style menus: Lintel, Sill and Stamp.
- A Plugins > Looks page, with Restore (Restore Daylight look).
- `/looks` reports the style on the player frame. `/looks lintel`, `/looks sill`, `/looks stamp` and `/looks off` point at Daylight's Frame style menu. Daylight has no public call that lets a plugin select a frame style, so these commands do not write Daylight's saved settings.

### Notes
- If Daylight's plugin API is older than 1.9, Looks adds nothing and prints: "Looks: Daylight UI is missing the settings Looks needs, so no frame or glow styles were added."
