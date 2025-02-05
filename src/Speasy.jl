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

include("utils.jl")
include("types.jl")
include("methods.jl")
include("dataset.jl")

speasy() = @pyconst(pyimport("speasy"))

function get_data(args...)
    res = @pyconst(pyimport("speasy").get_data)(args...)
    return apply_recursively(res, SpeasyVariable, is_pylist)
end

function speasyplot end
function speasyplot! end

end
