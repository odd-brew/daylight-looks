# Changelog

## [0.1.0] - Unreleased

### Added
- Looks (DaylightUI Plugin) for World of Warcraft: Forever. It starts off. A fresh install does not change your frames.
- Three frame styles in Daylight's Frame style menus: Lintel, Sill and Stamp.
- A Plugins > Looks page, with Restore (Restore Daylight look).
- `/looks` reports the style on the player frame. `/looks lintel`, `/looks sill`, `/looks stamp` and `/looks off` point at Daylight's Frame style menu. Daylight has no public call that lets a plugin select a frame style, so these commands do not write Daylight's saved settings.

### Notes
- If Daylight's plugin API is older than 1.9, Looks adds nothing and prints: "Looks: Daylight UI is missing the settings Looks needs, so no frame or glow styles were added."
