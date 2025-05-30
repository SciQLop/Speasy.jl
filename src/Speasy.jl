"""
A Julia wrapper around `speasy`, a Python package to deal with main Space Physics WebServices.

Space Physics made EASY!

Links: [GitHub](https://github.com/SciQLop/speasy), [Documentation](https://speasy.readthedocs.io/)
"""
module Speasy

using PythonCall
using PythonCall.Core: pyisnone
using Dates
using NanoDates
using Unitful
import Base: get, getproperty, propertynames, getindex, size, summarysize
import PythonCall: PyArray, Py
using SpaceDataModel
import SpaceDataModel: times, units, meta, name

export speasy, SpeasyVariable, VariableAxis
export get_data
export times, units, meta, name
export replace_fillval_by_nan, replace_fillval_by_nan!, sanitize!
export isspectrogram
export speasyplot, speasyplot!
export DataSet, SpeasyProduct
export init_amda, init_cdaweb, init_csa, init_sscweb, init_archive, init_providers
export getdimarray

include("types.jl")
include("utils.jl")
include("methods.jl")
include("dataset.jl")
include("datamodel.jl")

const speasy = PythonCall.pynew()
const speasy_get_data = PythonCall.pynew()
const request_dispatch = PythonCall.pynew()
const TimeRangeType = Union{NTuple{2}}
const pyns = PythonCall.pynew()
const np = PythonCall.pynew()
const VERSION = Ref{String}()

function __init__()
    ccall(:jl_generating_output, Cint, ()) == 1 && return nothing
    PythonCall.pycopy!(speasy, pyimport("speasy"))
    PythonCall.pycopy!(speasy_get_data, pyimport("speasy").get_data)
    PythonCall.pycopy!(request_dispatch, pyimport("speasy.core.requests_scheduling.request_dispatch"))
    PythonCall.pycopy!(np, pyimport("numpy"))
    PythonCall.pycopy!(pyns, pyimport("numpy").timedelta64(1, "ns"))
    VERSION[] = pyconvert(String, speasy."__version__")
end

"""
    get_data(args...; drop_nan=false)

Get data using `speasy` Python package. We support the same arguments as `speasy.get_data`.

Set `drop_nan=true` to drop the nan values. Note that we need to do that in Python since we cannot convert `NaT` (not a time) to Julia.
"""
function get_data(args...; drop_nan=false, sanitize=false)
    v = speasy_get_data(_compat.(args)...)
    pyisnone(v) && return nothing
    drop_nan && (v = apply_recursively(v, py_drop_nan, is_pylist))
    sanitize && (v = apply_recursively(v, pysanitize, is_pylist))
    apply_recursively(v, SpeasyVariable, is_pylist)
end

function get_data(::Type{<:NamedTuple}, p, args...; names=nothing, kwargs...)
    data = get_data(p, args...; kwargs...)
    names = Tuple(Symbol.(@something names _key_names(p) Speasy.name.(data)))
    return NamedTuple{names}(data)
end

function get_data(ds::AbstractDataSet, args...; provider=provider(ds), kwargs...)
    products = products(ds; provider)
    get_data(products, args...; kwargs...)
end

"""
    ssc_get_data(args...)

Get data from SSCWeb. 

Compare to `get_data`, this function support `coord` as the last argument.
The following coordinates systems are available: geo, gm, gse, gsm, sm, geitod, geij2000. 
By default `gse` is used.
"""
function ssc_get_data(args...)
    v = @pyconst(speasy.ssc.get_data)(_compat.(args)...)
    pyisnone(v) ? nothing : SpeasyVariable(v)
end

init_amda() = request_dispatch."init_amda"(ignore_disabled_status=true)
init_cdaweb() = request_dispatch."init_cdaweb"(ignore_disabled_status=true)
init_csa() = request_dispatch."init_csa"(ignore_disabled_status=true)
init_sscweb() = request_dispatch."init_sscweb"(ignore_disabled_status=true)
init_archive() = request_dispatch."init_archive"(ignore_disabled_status=true)
init_providers() = request_dispatch."init_providers"(ignore_disabled_status=true)

function speasyplot end
function speasyplot! end

function getdimarray end
end
