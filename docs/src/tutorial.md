# Tutorial

This tutorial demonstrates how to use Speasy.jl to access space physics data.

## Basic Data Retrieval

The simplest way to get data is using string identifiers with [`get_data`](@ref):

```@example tutorial
using Speasy

# Get IMF data from AMDA
imf_data = get_data("amda/imf", "2016-6-2", "2016-6-3")
```

## Find the available datasets and parameters

```@docs; canonical=false
list_datasets
list_parameters
```

## Using Dynamic Inventory

The dynamic inventory allows you to browse available datasets interactively:

```@example tutorial
# Create a shorthand reference
const spz = speasy

# Access the AMDA data tree
amda_tree = spz.inventories.data_tree.amda

# Navigate to specific parameters
ace_imf = amda_tree.Parameters.ACE.MFI.ace_imf_all.imf
data = get_data(ace_imf, "2016-6-2", "2016-6-3");
```

## Using Macro

You can also use macro `@spz_str` to define multiple products:

```@example tutorial
products = spz"cda/OMNI_HRO_1MIN/flow_speed,E,Pressure"
Pressure_product = products[3]
```

Products are function-like objects, so you can call them with time intervals as arguments to get the data:

```@example tutorial
Pressure_product("2016-6-2", "2016-6-3")
```

## Multiple Parameters

You can request multiple parameters at once and get them as a NamedTuple:

```@example tutorial
products = [
    spz.inventories.tree.amda.Parameters.Wind.SWE.wnd_swe_kp.wnd_swe_vth,
    spz.inventories.tree.amda.Parameters.Wind.SWE.wnd_swe_kp.wnd_swe_pdyn,
    spz.inventories.tree.amda.Parameters.Wind.SWE.wnd_swe_kp.wnd_swe_n
]

data = get_data(NamedTuple, products, "2010-01-02", "2010-01-02T01")
```

```@example tutorial
data.wnd_swe_n
```

## Multiple Time Intervals

You can also request data for multiple time intervals:

```@example tutorial
products = [
    "cda/OMNI_HRO_1MIN/flow_speed",
    "cda/OMNI_HRO_1MIN/Pressure"
]

intervals = [
    ["2010-01-02", "2010-01-02T01"], 
    ["2009-08-02", "2009-08-02T01"]
]

get_data(products, intervals)
```

## Working with SSC Data

For trajectory data from SSCWeb:

```@example tutorial
# Get spacecraft trajectory (default is GSE)
trajectory = get_data("ssc/wind", "2016-6-2", "2016-6-3")

# Specify coordinate system 
trajectory_gsm = get_data("ssc/wind/gsm", "2016-6-2", "2016-6-3")
```

## Accessing Data Properties

```@example tutorial
times(data.wnd_swe_n) # timestamps
parent(data.wnd_swe_n) # data values
```