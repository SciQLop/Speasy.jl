module Speasy

using PythonCall
using Dates
using Unitful
import Base: getproperty, propertynames, getindex

export speasy, SpeasyVariable, VariableAxis
export get_data
export replace_fillval_by_nan, replace_fillval_by_nan!, sanitize, sanitize!
export isspectrogram
export speasyplot, speasyplot!
export DataSet
export init_amda, init_cdaweb, init_csa, init_sscweb, init_archive, init_providers

include("utils.jl")
include("types.jl")
include("methods.jl")
include("dataset.jl")

speasy() = @pyconst(pyimport("speasy"))

function get_data(args...)
    res = @pyconst(pyimport("speasy").get_data)(args...)
    return apply_recursively(res, SpeasyVariable, is_pylist)
end

init_amda() = @pyconst(pyimport("speasy.core.requests_scheduling.request_dispatch").init_amda)(ignore_disabled_status=true)
init_cdaweb() = @pyconst(pyimport("speasy.core.requests_scheduling.request_dispatch").init_cdaweb)(ignore_disabled_status=true)
init_csa() = @pyconst(pyimport("speasy.core.requests_scheduling.request_dispatch").init_csa)(ignore_disabled_status=true)
init_sscweb() = @pyconst(pyimport("speasy.core.requests_scheduling.request_dispatch").init_sscweb)(ignore_disabled_status=true)
init_archive() = @pyconst(pyimport("speasy.core.requests_scheduling.request_dispatch").init_archive)(ignore_disabled_status=true)
init_providers() = @pyconst(pyimport("speasy.core.requests_scheduling.request_dispatch").init_providers)(ignore_disabled_status=true)

function speasyplot end
function speasyplot! end

end
