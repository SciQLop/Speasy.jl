"""
    SpeasyProduct(id; provider=:cda, metadata=NoMetadata(), kw...)

The Speasy parameter `id` (`"provider/dataset/parameter"`, or a standalone one like `"amda/imf"`),
prefixed with `provider` when `id` names none; `kw` merge into `metadata`.
"""
struct SpeasyProduct{MD} <: DataSource
    id::String
    metadata::MD
end

function SpeasyProduct(id; provider=:cda, metadata=NoMetadata(), kwargs...)
    if !contain_provider(id)
        @info "Provider not found in $id, using $provider"
        id = "$provider/$id"
    end
    return SpeasyProduct(String(id), merge(metadata, kwargs))
end

name(p::SpeasyProduct) = getmeta(p, "name", p.id)
SpaceDataModel.getdata(p::SpeasyProduct, t0, t1; kw...) = get_data(p.id, t0, t1; kw...)

"""
    Speasy.Provider(name)

The datasets of the Speasy provider `name` (`:amda`, `:cda`, `:csa`, `:ssc`, `:archive`), a `SpaceDataModel.AbstractRegistry`:
`keys` are dataset ids, `provider[id]` a [`SpeasyDataset`](@ref). Bound as `Speasy.amda`, `Speasy.cda`, ….
"""
struct Provider <: AbstractRegistry
    name::Symbol
end

const amda, cda, csa, ssc, archive = Provider.((:amda, :cda, :csa, :ssc, :archive))

_inventory(p::Provider) = getproperty(speasy, p.name).flat_inventory
Base.keys(p::Provider) = pyconvert(Vector{String}, pylist(_inventory(p).datasets))
function Base.getindex(p::Provider, id::AbstractString)
    pyin(pystr(id), _inventory(p).datasets) || throw(KeyError(id))
    return SpeasyDataset(p, String(id))
end
name(p::Provider) = String(p.name)
Base.show(io::IO, p::Provider) = print(io, "Speasy.", p.name)

"""
    SpeasyDataset(provider, id)

The dataset `id` of `provider`; `keys` are its parameter ids, `ds[id]` a `Product`.
"""
struct SpeasyDataset <: AbstractDataset
    provider::Provider
    id::String
end

_index(ds::SpeasyDataset) = _inventory(ds.provider).datasets[pystr(ds.id)]
# A parameter uid is "dataset/parameter" on CDAWeb-like providers but standalone on AMDA.
_uid(ds::SpeasyDataset, var) = (uid = "$(ds.id)/$var"; pyin(pystr(uid), _inventory(ds.provider).parameters) ? uid : String(var))
_product_id(ds::SpeasyDataset, var) = "$(ds.provider.name)/$(_uid(ds, var))"

Base.keys(ds::SpeasyDataset) = [String(chopprefix(pyconvert(String, p.spz_uid()), "$(ds.id)/")) for p in _index(ds)]
name(ds::SpeasyDataset) = ds.id
Base.show(io::IO, ds::SpeasyDataset) = print(io, ds.provider, "[", repr(ds.id), "]")

function getmeta(ds::SpeasyDataset)
    ParameterIndex = @pyconst pyimport("speasy.core.inventory.indexes").ParameterIndex
    attrs = PyDict{String, Py}(_index(ds).__dict__)
    return Dict{String, Any}(k => pyconvert(Any, v) for (k, v) in attrs if !pyisinstance(v, ParameterIndex))
end

function SpaceDataModel.getdata(ds::SpeasyDataset, t0, t1; kw...)
    vars = keys(ds)
    return Dict(zip(vars, get_data([_product_id(ds, v) for v in vars], t0, t1; kw...)))
end
SpaceDataModel.getdata(p::Product{SpeasyDataset}, t0, t1; kw...) =
    get_data(_product_id(parent(p), p.variable), t0, t1; kw...)

Base.show(io::IO, p::SpeasyProduct) = print(io, "spz", repr(p.id))
function Base.show(io::IO, ::MIME"text/plain", p::SpeasyProduct)
    printstyled(io, "SpeasyProduct: "; bold=true)
    printstyled(io, p.id; color=:yellow)
    for (k, v) in pairs(p.metadata)
        print(io, "\n  ", k, ": ", v)
    end
end

"""
    spz"provider/dataset/parameter"
    spz"provider/dataset/parameter1,parameter2"

String macro to create a SpeasyProduct from a string identifier.
Supports multiple parameters separated by commas, which returns a tuple of SpeasyProduct objects.

# Examples
```julia
# Single parameter
product = spz"cda/OMNI_HRO_1MIN/flow_speed"

# Multiple parameters
products = spz"cda/OMNI_HRO_1MIN/flow_speed,Pressure"
```
"""
macro spz_str(s)
    if contains(s, ",")
        # Multiple parameters case
        parts = split(s, "/")
        if length(parts) < 3
            error("Invalid format. Expected 'provider/dataset/parameter1,parameter2'")
        end
        provider_dataset = join(parts[1:end-1], "/")
        parameters = strip.(split(parts[end], ","))
        # Create tuple expression
        product_exprs = (:(SpeasyProduct($("$provider_dataset/$param"))) for param in parameters)
        ex = Expr(:tuple, product_exprs...)
        return ex
    else
        # Single parameter case
        return :(SpeasyProduct($s))
    end
end