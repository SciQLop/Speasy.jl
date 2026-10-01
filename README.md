# Speasy

[![DOI](https://zenodo.org/badge/922473963.svg)](https://doi.org/10.5281/zenodo.15171895)

[![Coverage](https://codecov.io/gh/SciQLop/Speasy.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/SciQLop/Speasy.jl)

A Julia wrapper around [Speasy](https://github.com/SciQLop/speasy), a Python package to deal with main Space Physics WebServices.

**Documentation**: [![Dev](https://img.shields.io/badge/docs-dev-blue.svg?logo=julia)](https://SciQLop.github.io/Speasy.jl/dev/)

## Quick Start

```julia
using Pkg; Pkg.add("Speasy")
using Speasy

get_data("amda/imf", "2016-6-2", "2016-6-5")
```

> [!NOTE]
> It is advisable to load this package before any others, as it relies on OpenSSL underpinnings. Compatibility issues may arise between Python and Julia if it is not prioritized accordingly.