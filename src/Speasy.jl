module Speasy

using PythonCall
using PythonCall.Core: pyisnone
using Dates
using NanoDates
using Unitful
import Base: getproperty, propertynames, getindex, size

export speasy, SpeasyVariable, VariableAxis
export get_data
export replace_fillval_by_nan, replace_fillval_by_nan!, sanitize, sanitize!
export isspectrogram
export speasyplot, speasyplot!
export DataSet
export init_amda, init_cdaweb, init_csa, init_sscweb, init_archive, init_providers

include("types.jl")
include("utils.jl")
include("methods.jl")
include("dataset.jl")

const speasy = PythonCall.pynew()
const request_dispatch = PythonCall.pynew()
const TimeRangeType = Union{NTuple{2}}

function __init__()
    ccall(:jl_generating_output, Cint, ()) == 1 && return nothing
    PythonCall.pycopy!(speasy, pyimport("speasy"))
    PythonCall.pycopy!(request_dispatch, pyimport("speasy.core.requests_scheduling.request_dispatch"))
end

function get_data(args...)
    res = speasy."get_data"(args...)
    return apply_recursively(res, SpeasyVariable, is_pylist)
end

function get_data(p, trange::TimeRangeType; kwargs...)
    res = speasy.get_data(p, trange...; kwargs...)
    return apply_recursively(res, SpeasyVariable, is_pylist)
end

function get_data(::Type{<:NamedTuple}, args...; keys=nothing, kwargs...)
    data = get_data(args...; kwargs...)
    keys = Tuple(Symbol.(@something keys Speasy.name.(data)))
    return NamedTuple{keys}(data)
end

init_amda() = request_dispatch."init_amda"(ignore_disabled_status=true)
init_cdaweb() = request_dispatch."init_cdaweb"(ignore_disabled_status=true)
init_csa() = request_dispatch."init_csa"(ignore_disabled_status=true)
init_sscweb() = request_dispatch."init_sscweb"(ignore_disabled_status=true)
init_archive() = request_dispatch."init_archive"(ignore_disabled_status=true)
init_providers() = request_dispatch."init_providers"(ignore_disabled_status=true)

function speasyplot end
function speasyplot! end

end
