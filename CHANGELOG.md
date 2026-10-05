# Changelog

## [Unreleased]

### Changed

- **Breaking**: `get_data(...; sanitize = true)` masks with `SpaceDataModel.mask_invalid!`. `sanitize!`, `replace_invalid!` and `replace_fillval_by_nan!` are removed; use `SpaceDataModel.mask_invalid(var)`, which keeps numpy's memory order.

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