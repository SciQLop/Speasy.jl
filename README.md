# Speasy

[![DOI](https://zenodo.org/badge/922473963.svg)](https://doi.org/10.5281/zenodo.15171895)

A Julia wrapper around [Speasy](https://github.com/SciQLop/speasy), a Python package to deal with main Space Physics WebServices.

## Quick Start

```julia
using Pkg; Pkg.add("Speasy")
using Speasy

# Providers `Speasy.amda`, `Speasy.cda`, `Speasy.csa`, `Speasy.ssc`, `Speasy.archive` index datasets by id
filter(contains(r"OMNI.*HRO"), keys(Speasy.cda))   # dataset ids
ds = Speasy.cda["OMNI_HRO_1MIN"]
keys(ds); getmeta(ds)                              # parameter ids, dataset attributes

t0, t1 = "2016-6-2", "2016-6-3"
getdata(ds["flow_speed"], t0, t1)                  # ds["flow_speed"] == spz"cda/OMNI_HRO_1MIN/flow_speed"
spz"amda/imf"(t0, t1)                              # calling a product is `getdata`
getdata.((ds["E"], ds["Pressure"]), t0, t1)
getdata(ds, t0, t1)                                # every parameter, Dict by id
```

`get_data` takes the same arguments as Python `speasy.get_data`.
