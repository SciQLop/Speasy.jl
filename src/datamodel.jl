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

struct Provider
    name::Symbol
end

const amda, cda, csa, ssc, archive = Provider.((:amda, :cda, :csa, :ssc, :archive))

# `speasy.<provider>` is `None` until its `init_*` has run (CSA by default); touching the registry is the intent to use it.
const _init_names = (cda = :cdaweb, ssc = :sscweb)
function _inventory(p::Provider)
    py = getproperty(speasy, p.name)
    if pyisnone(py)
        getfield(Speasy, Symbol(:init_, get(_init_names, p.name, p.name)))()
        py = getproperty(speasy, p.name)
    end
    return py.flat_inventory
end
# Strings cross from Python newline-joined: one call and one conversion instead of one per element,
# which dominated the cost.
_pylines(py) = split(pyconvert(String, @pyconst(pyeval("lambda xs: '\\n'.join(xs)", Main))(py)), '\n'; keepempty = false)
Base.keys(p::Provider) = String.(_pylines(_inventory(p).datasets))
function Base.getindex(p::Provider, id::AbstractString)
    pyin(pystr(id), _inventory(p).datasets) || SpaceDataModel._unknown_id(name(p), keys(p), id)
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
# Parameter id => uid.
# The uid is "dataset/parameter" on CDAWeb-like providers but standalone on AMDA, so read it from the index.
function _parameters(ds::SpeasyDataset)
    uids = _pylines(@pyconst(pyeval("lambda idx: [p.spz_uid() for p in idx]", Main))(_index(ds)))
    prefix = ds.id * "/"
    return [String(chopprefix(uid, prefix)) => uid for uid in uids]
end
_spz_id(ds::SpeasyDataset, uid) = string(ds.provider.name, "/", uid)
function _product_id(ds::SpeasyDataset, var)
    params = _parameters(ds)
    i = findfirst(==(String(var)) ∘ first, params)
    isnothing(i) && SpaceDataModel._unknown_id(ds.id, first.(params), var)
    return _spz_id(ds, last(params[i]))
end

Base.keys(ds::SpeasyDataset) = first.(_parameters(ds))
name(ds::SpeasyDataset) = ds.id
function Base.getindex(ds::SpeasyDataset, var::Union{AbstractString, Symbol})
    _product_id(ds, var)
    return Product(ds, var)
end
Base.show(io::IO, ds::SpeasyDataset) = print(io, ds.provider, "[", repr(ds.id), "]")

function getmeta(ds::SpeasyDataset)
    ParameterIndex = @pyconst pyimport("speasy.core.inventory.indexes").ParameterIndex
    attrs = PyDict{String, Py}(_index(ds).__dict__)
    return Dict{String, Any}(k => pyconvert(Any, v) for (k, v) in attrs if !pyisinstance(v, ParameterIndex))
end

function SpaceDataModel.getdata(ds::SpeasyDataset, t0, t1; kw...)
    params = _parameters(ds)
    return Dict(zip(first.(params), get_data([_spz_id(ds, uid) for (_, uid) in params], t0, t1; kw...)))
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