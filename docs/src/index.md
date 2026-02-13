# Speasy.jl

[![DOI](https://zenodo.org/badge/922473963.svg)](https://doi.org/10.5281/zenodo.15171895)
[![version](https://juliahub.com/docs/General/Speasy/stable/version.svg)](https://juliahub.com/ui/Packages/General/Speasy)

`Speasy.jl` provides access to space physics data from various web services including:

- Automated Multi-Dataset Analysis (AMDA)
- Coordinated Data Analysis Web (CDAWeb)
- Cluster Science Archive (CSA)
- Satellite Situation Center Web (SSCWeb)

## Features

- Easy access to space physics data with a unified interface [`get_data`](@ref)
- Integration with popular Julia packages like [`DimensionalData.jl`](https://github.com/rafaqz/DimensionalData.jl).

## Installation

```julia
using Pkg
Pkg.add("Speasy")
```

## Quick Start

```julia
using Speasy

# Get Interplanetary Magnetic Field data
imf_data = get_data("amda/imf", "2016-6-2", "2016-6-5")

# Use dynamic inventory
const spz = speasy
amda_tree = spz.inventories.data_tree.amda
ace_data = get_data(amda_tree.Parameters.ACE.MFI.ace_imf_all.imf, "2016-6-2", "2016-6-5")
```

!!! note "Loading Order"
    It is advisable to load Speasy.jl before other packages, as it relies on OpenSSL underpinnings. Compatibility issues may arise between Python and Julia if it is not prioritized accordingly.