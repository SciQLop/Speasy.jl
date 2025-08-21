"""
    list_parameters(provider, [dataset])

Find the available parameters for a given `provider` or for a specific `dataset` from `provider`.

# Examples
```jldoctest
# List all parameters from AMDA provider
list_parameters(:amda)

# List parameters from specific CDA dataset
list_parameters(:cda, "SOHO_ERNE-HED_L2-1MIN")

# output
5-element Vector{String}:
 "est"
 "PH"
 "AH"
 "PHC"
 "AHC"
```

See also: [`list_datasets`](@ref)
"""
function list_parameters(s)
    provider_py = getproperty(speasy, s)
    dict = provider_py.flat_inventory.parameters
    return pyconvert(PyList{String}, pylist(dict))
end

function list_parameters(provider, dataset)
    provider_py = getproperty(speasy, String(provider))
    dataset_py = provider_py.flat_inventory.datasets[pystr(dataset)] # this is a iterator
    return map(spz_name, dataset_py)
end

spz_name(py) = pyconvert(String, py.spz_name())

"""
    list_datasets(provider, [term...])

Find the available datasets for a given provider, optionally filtered by search terms (only datasets containing all specified terms will be returned.)

# Examples
```jldoctest
# List all datasets from AMDA provider
list_datasets(:amda)

# List CDA datasets containing "OMNI"
list_datasets(:cda, :OMNI)

# List CDA datasets containing both "OMNI" and "HRO"
list_datasets(:cda, :OMNI, :HRO)

# output
4-element Vector{String}:
 "OMNI_HRO_1MIN"
 "OMNI_HRO2_1MIN"
 "OMNI_HRO_5MIN"
 "OMNI_HRO2_5MIN"
```

See also: [`list_parameters`](@ref)
"""
function list_datasets(provider)
    provider_py = getproperty(speasy, provider)
    dict = provider_py.flat_inventory.datasets
    return pyconvert(PyList{String}, pylist(dict))
end

function list_datasets(provider, s...)
    provider_py = getproperty(speasy, provider)
    dict = provider_py.flat_inventory.datasets
    datasets = String[]
    pys = pystr.(s)
    for ds in dict
        all(x -> pyin(x, ds), pys) && push!(datasets, pyconvert(String, ds))
    end
    return datasets
end
