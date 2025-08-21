# Speasy

[![Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://SciQLop.github.io/Speasy.jl/dev/)

[![Build Status](https://github.com/SciQLop/Speasy.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/SciQLop/Speasy.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![Coverage](https://codecov.io/gh/SciQLop/Speasy.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/SciQLop/Speasy.jl)

A Julia wrapper around [Speasy](https://github.com/SciQLop/speasy), a Python package to deal with main Space Physics WebServices.

## Installation

```julia
using Pkg
Pkg.add("Speasy.jl")
```

## Quick Start

```julia
using Speasy
const spz = speasy

get_data("amda/imf", "2016-6-2", "2016-6-5")

# Dynamic inventory
amda_tree = spz.inventories.data_tree.amda
get_data(amda_tree.Parameters.ACE.MFI.ace_imf_all.imf, "2016-6-2", "2016-6-5") 
```

> [!NOTE]
> It is advisable to load this package before any others, as it relies on OpenSSL underpinnings. Compatibility issues may arise between Python and Julia if it is not prioritized accordingly.