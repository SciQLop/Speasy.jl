# Changelog

## [Unreleased]

## [0.4.7] - 2025-10-17

### Changed

- **Breaking**: drop `add_unit=false` argument when converting to `DimArray`. Use `DimArray(v) .* unit(v)` instead.

## [0.4.0] - 2025-08-08

### Changed

- **Breaking**: do not use column names as dimension name
- **Breaking**: make sanitize=true the default and apply it after SpeasyVariable conversion ([#16](https://github.com/SciQLop/Speasy.jl/issues/16))

[Unreleased]: https://github.com/SciQLop/Speasy.jl/compare/v0.4.7...HEAD
[0.4.7]: https://github.com/SciQLop/Speasy.jl/compare/v0.4.6...v0.4.7
[0.4.0]: https://github.com/SciQLop/Speasy.jl/compare/v0.3.0...v0.4.0