"""
    list_parameters(provider, [dataset]; verbose=false)

Find the available parameter ids for a given `provider` or for a specific `dataset` from `provider`;
the latter are `keys(provider[dataset])`.

Set `verbose=true` to print the metadata of the dataset.

# Examples
```julia
list_parameters(:amda)  # all parameters from AMDA
```

```jldoctest
julia> list_parameters(:cda, "SOHO_ERNE-HED_L2-1MIN")
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
```julia
find_datasets(:amda)       # all datasets from AMDA
find_datasets(:cda, :OMNI) # CDA datasets containing "OMNI"
```

```jldoctest
julia> find_datasets(:cda, :OMNI, :HRO)
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
