# Tutorial

## Find datasets and parameters

Each provider (`Speasy.amda`, `Speasy.cda`, `Speasy.csa`, `Speasy.ssc`, `Speasy.archive`) indexes datasets by id; a dataset indexes its parameters.

```@example tutorial
using Speasy
filter(contains(r"OMNI.*HRO"), keys(Speasy.cda))
```

```@example tutorial
ds = Speasy.cda["SOHO_ERNE-HED_L2-1MIN"]
keys(ds)
```

```@example tutorial
getmeta(ds)
```

## Get data

`ds[parameter]` and `spz"provider/dataset/parameter"` both give a [`SpeasyProduct`](@ref). `getdata(product, t0, t1)` fetches it, as does calling the product:

```@example tutorial
getdata(ds["PH"], "2016-6-2", "2016-6-3")
```

```@example tutorial
imf = spz"amda/imf"
imf("2016-6-2", "2016-6-3")
```

Several parameters: broadcast, or `getdata(ds, t0, t1)` for all of a dataset's.

```@example tutorial
omni = Speasy.cda["OMNI_HRO_1MIN"]
flow_speed, pressure = getdata.((omni["flow_speed"], omni["Pressure"]), "2016-6-2", "2016-6-3")
times(pressure), parent(pressure)
```

SSCWeb trajectories take the coordinate system as a last path segment (default `gse`):

```@example tutorial
spz"ssc/wind/gsm"("2016-6-2", "2016-6-3")
```

## Python-style `get_data`

[`get_data`](@ref) takes the same arguments as Python `speasy.get_data`, including its dynamic inventory:

```@example tutorial
ace_imf = speasy.inventories.data_tree.amda.Parameters.ACE.MFI.ace_imf_all.imf
get_data(ace_imf, "2016-6-2", "2016-6-3")
```
