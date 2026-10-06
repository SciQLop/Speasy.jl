# Changelog

## [Unreleased]

### Changed

- **Breaking**: time is the last dimension by default, with dimension `i` the ISTP `DEPEND_i`, zero-copy; time-varying axes follow. The `transpose` keyword of `get_data` and `SpeasyVariable` is replaced by `layout = :julia` (default) or `:python` (numpy's time-first order). `DimArray(::SpeasyVariable)` names every dimension, time as `Ti` wherever it is; `DimArray(::VariableAxis)` is removed.
- **Breaking**: `get_data(...; sanitize = true)` masks with `SpaceDataModel.mask_invalid!`. `sanitize!`, `replace_invalid!` and `replace_fillval_by_nan!` are removed; use `SpaceDataModel.mask_invalid(var)`, which keeps numpy's memory order.

### Fixed

- `view` of a `SpeasyVariable` slices time-varying axes along their time dimension and drops the axes of integer-indexed dimensions.
- Non-scalar indexing (`v[2, 1:5]`) returns the sliced axes instead of the source's.
- `Array(::SpeasyVariable)` copies in memory order.
- Printing a non-concrete `SpeasyVariable` type (e.g. `SpeasyVariable`, or in stack traces) no longer throws; types print with Julia's default `show`, which also removes ~3000 method invalidations on load.

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