# Speasy

[![Build Status](https://github.com/Beforerr/Speasy.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Beforerr/Speasy.jl/actions/workflows/CI.yml?query=branch%3Amain)

A simple Julia wrapper around [Speasy](https://github.com/SciQLop/speasy), a Python package to deal with main Space Physics WebServices.

## Features

- Integration with [`DimensionalData`](https://github.com/rafaqz/DimensionalData.jl) (recommended), [`TimeseriesToolsExt`](https://github.com/brendanjohnharris/TimeseriesTools.jl), [`TimeSeries`](https://github.com/JuliaStats/TimeSeries.jl), and [`Makie`](https://github.com/MakieOrg/Makie.jl).

## Installation

```julia
using Pkg
Pkg.add("Speasy.jl")
```

## Examples

```julia
using Speasy
const spz = speasy()

get_data("amda/imf", "2016-6-2", "2016-6-5")

# Dynamic inventory
amda_tree = spz.inventories.data_tree.amda
get_data(amda_tree.Parameters.ACE.MFI.ace_imf_all.imf, "2016-6-2", "2016-6-5") 
```

```julia
# More complex requests
products = [
    spz.inventories.tree.amda.Parameters.Wind.SWE.wnd_swe_kp.wnd_swe_vth,
    spz.inventories.tree.amda.Parameters.Wind.SWE.wnd_swe_kp.wnd_swe_pdyn,
    spz.inventories.tree.amda.Parameters.Wind.SWE.wnd_swe_kp.wnd_swe_n,
    spz.inventories.tree.cda.Wind.WIND.MFI.WI_H2_MFI.BGSE,
    spz.inventories.tree.ssc.Trajectories.wind,
]
intervals = [["2010-01-02", "2010-01-02T10"], ["2009-08-02", "2009-08-02T10"]]
get_data(products, intervals)
```


> [!NOTE]
> It is advisable to load this package before any others, as it relies on OpenSSL underpinnings. Compatibility issues may arise between Python and Julia if it is not prioritized accordingly.