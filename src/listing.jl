"""
    list_parameters(provider, [dataset]; verbose=false)

Find the available parameter ids for a given `provider` or for a specific `dataset` from `provider`;
the latter are `keys(provider[dataset])`.

Set `verbose=true` to print the metadata of the dataset.

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

See also: [`find_datasets`](@ref)
"""
list_parameters(provider) = _pystrings(_inventory(Provider(Symbol(provider))).parameters)

function list_parameters(provider, dataset; verbose = false)
    ds = Provider(Symbol(provider))[String(dataset)]
    verbose && @info "DatasetIndex Metadata" metadata = getmeta(ds)
    return keys(ds)
end

"""
    find_datasets(provider, [term...])

Find the available datasets for a given provider, optionally filtered by search terms (only datasets containing all specified terms will be returned.)

# Examples
```jldoctest
# List all datasets from AMDA provider
find_datasets(:amda)

# List CDA datasets containing "OMNI"
find_datasets(:cda, :OMNI)

# List CDA datasets containing both "OMNI" and "HRO"
find_datasets(:cda, :OMNI, :HRO)

# output
4-element Vector{String}:
 "OMNI_HRO_1MIN"
 "OMNI_HRO2_1MIN"
 "OMNI_HRO_5MIN"
 "OMNI_HRO2_5MIN"
```

See also: [`list_parameters`](@ref)
"""
find_datasets(provider, terms...) =
    filter(ds -> all(t -> occursin(string(t), ds), terms), keys(Provider(Symbol(provider))))
