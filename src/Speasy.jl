"""
A Julia wrapper around `speasy`, a Python package to deal with main Space Physics WebServices.

Space Physics made EASY!

Links: [GitHub](https://github.com/SciQLop/speasy), [Documentation](https://speasy.readthedocs.io/)
"""
module Speasy

using Accessors: @set
using PythonCall
using PythonCall.Core: pyisnone
using UnixTimes: UnixTime
using Unitful
using ConcreteStructs
import Base: getproperty, summarysize, similar
import PythonCall: PyArray, Py
using SpaceDataModel
import SpaceDataModel: times, units, meta, name

export speasy, SpeasyVariable, VariableAxis
export get_data
export times, units, name, meta
export sanitize!, replace_fillval_by_nan!, replace_invalid!
export speasyplot, speasyplot!
export SpeasyProduct
export @spz_str
export init_amda, init_cdaweb, init_csa, init_sscweb, init_archive, init_providers
export list_parameters, find_datasets

include("utils.jl")
include("types.jl")
include("methods.jl")
include("dataset.jl")
include("datamodel.jl")
include("providers.jl")
include("listing.jl")

const speasy = PythonCall.pynew()
const speasy_get_data = PythonCall.pynew()
const request_dispatch = PythonCall.pynew()
const VERSION = Ref{String}()

function __init__()
    ccall(:jl_generating_output, Cint, ()) == 1 && return nothing
    PythonCall.pycopy!(speasy, pyimport("speasy"))
    PythonCall.pycopy!(speasy_get_data, pyimport("speasy").get_data)
    PythonCall.pycopy!(request_dispatch, pyimport("speasy.core.requests_scheduling.request_dispatch"))
    VERSION[] = pyconvert(String, speasy."__version__")
    return
end

"""
    get_data(args...; drop_nan=false)

Get data using `speasy` Python package. We support the same arguments as `speasy.get_data`.

Set `drop_nan=true` to drop the nan values. Note that we need to do that in Python since we cannot convert `NaT` (not a time) to Julia.
"""
function get_data(args...; kw...)
    provider = get_provider(args[1])
    if provider in ("ssc", "sscweb")
        splits = split(args[1], "/")
        prod = splits[2]
        coord = get(splits, 3, "gse")
        return ssc_get_data(prod, args[2:end]..., coord; kw...)
    else
        return general_get_data(args...; kw...)
    end
end

function get_data(::Type{<:NamedTuple}, p, args...; names = nothing, kwargs...)
    data = get_data(p, args...; kwargs...)
    names = if isnothing(names) && isnothing(_key_names(p))
        # Handle mixed case where some data is nothing and some is valid
        map(zip(p, data)) do (param, datum)
            isnothing(datum) ? split(param, '/')[end] : name(datum)
        end
    else
        @something names _key_names(p)
    end
    return NamedTuple{Tuple(Symbol.(names))}(data)
end

function get_data(ds::AbstractDataSet, args...; provider = provider(ds), kwargs...)
    pds = products(ds; provider)
    return get_data(pds, args...; kwargs...)
end

for provider in (:amda, :cdaweb, :csa, :sscweb, :archive, :providers)
    f = Symbol(:init_, provider)
    @eval $f() = request_dispatch.$f(ignore_disabled_status = true)
end

# https://speasy.readthedocs.io/en/stable/_modules/speasy/core/direct_archive_downloader/direct_archive_downloader.html#RegularSplitDirectDownload.get_product
function get_product(url_pattern, variable, start_time, stop_time; split_rule = "regular", kwargs...)
    start_time = string(start_time) # Python side assume datetime-like (see `make_utc_datetime` in https://github.com/SciQLop/speasy/blob/main/speasy/core/__init__.py#L145)
    stop_time = string(stop_time)
    spz_get_product = @pyconst pyimport("speasy.core.direct_archive_downloader").get_product
    v = spz_get_product(; url_pattern, variable, start_time, stop_time, split_rule, kwargs...)
    pyisnone(v) && return nothing
    return SpeasyVariable(v)
end

function speasyplot end
function speasyplot! end

function getdimarray end
end
