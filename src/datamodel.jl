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

"""SpeasyDataset(provider, id)"""
struct SpeasyDataset{P} <: AbstractDataset
    provider::P
    id::String
end

struct Provider <: AbstractDict{String, SpeasyDataset{Provider}}
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
# The `str`s of an iterable, read through the C API: ~2x faster than a newline join-and-split
# and ~3x than per-element `pyconvert` on `keys(Speasy.cda)` (~3k ids).
# `PythonCall.C` is internal; the names used here also exist on PythonCall's v1 branch.
const PyC = PythonCall.C
function _pystrings(py)
    asutf8 = Libc.Libdl.dlsym(PythonCall.python_library_handle(), :PyUnicode_AsUTF8AndSize)
    out = String[]
    n = Ref{PyC.Py_ssize_t}()
    GC.@preserve py begin
        it = PyC.PyObject_GetIter(py)
        it == PyC.PyNULL && PythonCall.Core.pythrow()
        while (k = PyC.PyIter_Next(it)) != PyC.PyNULL
            ptr = ccall(asutf8, Ptr{UInt8}, (PyC.PyPtr, Ptr{PyC.Py_ssize_t}), k, n)
            ptr == C_NULL || push!(out, unsafe_string(ptr, n[]))
            PyC.Py_DecRef(k)
            ptr == C_NULL && break
        end
        PyC.Py_DecRef(it)
    end
    PyC.PyErr_Occurred() == PyC.PyNULL || PythonCall.Core.pythrow()
    return out
end
Base.keys(p::Provider) = _pystrings(_inventory(p).datasets)
function Base.getindex(p::Provider, id::AbstractString)
    pyin(pystr(id), _inventory(p).datasets) || SpaceDataModel._unknown_id(name(p), keys(p), id)
    return SpeasyDataset(p, String(id))
end
Base.length(p::Provider) = Int(pylen(_inventory(p).datasets))
function Base.iterate(p::Provider, (ids, i) = (keys(p), 1))
    i > length(ids) && return nothing
    return ids[i] => SpeasyDataset(p, ids[i]), (ids, i + 1)
end
name(p::Provider) = String(p.name)
# `AbstractDict` equality and hashing would walk the whole inventory.
Base.:(==)(a::Provider, b::Provider) = a.name == b.name
Base.isequal(a::Provider, b::Provider) = a == b
Base.hash(p::Provider, h::UInt) = hash(p.name, hash(Provider, h))
Base.show(io::IO, p::Provider) = print(io, "Speasy.", p.name)

_index(ds::SpeasyDataset) = _inventory(ds.provider).datasets[pystr(ds.id)]
# Parameter id => uid.
# The uid is "dataset/parameter" on CDAWeb-like providers but standalone on AMDA, so read it from the index.
function _parameters(ds::SpeasyDataset)
    uids = _pystrings(@pyconst(pyeval("lambda idx: [p.spz_uid() for p in idx]", Main))(_index(ds)))
    prefix = ds.id * "/"
    return [String(chopprefix(uid, prefix)) => uid for uid in uids]
end
_spz_id(ds::SpeasyDataset, uid) = string(ds.provider.name, "/", uid)

Base.keys(ds::SpeasyDataset) = first.(_parameters(ds))
name(ds::SpeasyDataset) = ds.id
function Base.getindex(ds::SpeasyDataset, var::Union{AbstractString, Symbol})
    params = _parameters(ds)
    i = findfirst(==(String(var)) ∘ first, params)
    isnothing(i) && SpaceDataModel._unknown_id(ds.id, first.(params), var)
    return SpeasyProduct(_spz_id(ds, last(params[i])))
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

`SpeasyProduct("provider/dataset/parameter")`.
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