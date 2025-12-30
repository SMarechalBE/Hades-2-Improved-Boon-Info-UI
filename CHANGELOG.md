# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2025-12-30

### Added

- Banned boons are now prefixed with a lock icon in requirement lists. 
- Tracked/pinned boons are now prefixed with a pin icon in the requirements lists
- The icons above can be separately disabled in configuration. Both defaults to enabled.  

### Fixed

- Small issue with default filter wrongly applied when out of a run

## [1.1.0] - 2025-12-29

### Added

- Configuration parameter for default availability logic of sacrifice boons

### Changed

- Default availability logic for sacrifice boons is now always unavailable
- Improved duo boon unavailability logic to trigger only when both gods wouldn't fit into god pool

### Fixed

- Out of pool gods now correctly displayed as in-pool when currently being offered
- Issue with some unavailable duo boons that were wrongly displayed as unfulfilled

## [1.0.1] - 2025-12-17

### Fixed

- Used bad image extensions for readme

## [1.0.0] - 2025-12-17

### Added

- Unfulfilled nuanced states for more granularity
- Filtering behaviour on Boon offering pages for Olympian gods

### Changed

- Gave more "availability" weight to _god unavailable_ relative to _sacrifice_ boons as those are theoretically always available

### Fixed

- Bug with requirement heading displayed in white even when fulfilled
- Gods sometimes were shown as unavailable when a run was not ongoing
- 4th god picked during a run would show his/her offerings as unavailable
- God unavailable behaviour will be more consistent with duo boons

### Removed

- Public API access as the mod should work in all situations since it directly relies on game data

## [0.3.0] - 2025-12-10

### Added

- Unfulfilled boon category to further improve clarity to better differentiate which boons are available to those that still need a requirement.
- Color transparency for Denied boons, should look much better now in the codex.

### Changed

- Game namespace to game specific calls for an improved readability.

## [0.2.1] - 2025-12-09

### Added

- Public definitions for consumption

### Fixed

- Crash when scrolling down Chaos boon offerings.

## [0.2.0] - 2025-12-08

### Added

- Boons banned from vow of denial follow the same logic as other boons applied to requirements.
- Boon state getter added to public space for to get consumed as dependency.

## [0.1.0] - 2025-12-08

### Added

- First version of the mod!

[unreleased]: https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/compare/1.2.0...HEAD
[1.2.0]: https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/compare/1.0.1...1.1.0
[1.0.1]: https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/compare/0.3.0...1.0.0
[0.3.0]: https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/compare/0.2.1...0.3.0
[0.2.1]: https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/compare/0.2.0...0.2.1
[0.2.0]: https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/compare/9a9334ef72bc6531721d2af5941171b58a519c84...0.1.0
