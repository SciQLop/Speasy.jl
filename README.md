# Speasy

[![Build Status](https://github.com/Beforerr/Speasy.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Beforerr/Speasy.jl/actions/workflows/CI.yml?query=branch%3Amain)

A simple Julia wrapper around the [Speasy](https://github.com/SciQLop/speasy), a Python package to deal with main Space Physics WebServices.

## Features

- Integration with [`DimensionalData`](https://github.com/rafaqz/DimensionalData.jl) (recommended), [`TimeseriesToolsExt`](https://github.com/brendanjohnharris/TimeseriesTools.jl), [`TimeSeries`](https://github.com/JuliaStats/TimeSeries.jl), and [`Makie`](https://github.com/MakieOrg/Makie.jl).

## Installation

```julia
using Pkg
Pkg.add("https://github.com/Beforerr/Speasy.jl")
```

## Examples

```julia
using Speasy
get_data("amda/imf", "2016-6-2", "2016-6-5")
```

> [!NOTE]
> It is advisable to load this package before any others, as it relies on OpenSSL underpinnings. Compatibility issues may arise between Python and Julia if it is not prioritized accordingly.