module Speasy

using PythonCall
using Dates
using Unitful
import Base: getproperty, propertynames, getindex

export speasy, SpeasyVariable
export get_data
export replace_fillval_by_nan, replace_fillval_by_nan!, sanitize, sanitize!
export speasyplot, speasyplot!

include("utils.jl")
include("methods.jl")

speasy() = @pyconst(pyimport("speasy"))

"""
A wrapper of `speasy.SpeasyVariable`.
"""
struct SpeasyVariable
    py::Py
end

function get_data(args...)
    res = @pyconst(pyimport("speasy").get_data)(args...)
    return apply_recursively(res, SpeasyVariable, is_pylist)
end

getindex(var::SpeasyVariable, s::String) = SpeasyVariable(var.py[s])
getindex(var::SpeasyVariable, s::Symbol) = getindex(var, string(s))

name(var) = pyconvert(String, var.py.name)
values(var) = pyconvert(Array, var.py.values)
time(var) = pyconvert_time(var.py.time)
columns(var) = pyconvert(Vector{Symbol}, var.py.columns)
meta(var) = pyconvert(Dict, var.py.meta)

function units(var)
    u_str = pyconvert(String, var.py.unit)
    try
        uparse(u_str)
    catch
        @info "Cannot parse unit $u_str"
        u_str
    end
end

const speasy_properties = (:name, :values, :time, :columns, :meta, :units)

function getproperty(var::SpeasyVariable, s::Symbol)
    s in (:py,) && return getfield(var, s)
    s in speasy_properties && return eval(s)(var)
    return getproperty(var.py, s)
end

propertynames(var::SpeasyVariable) = union(fieldnames(SpeasyVariable), speasy_properties)

function speasyplot end
function speasyplot! end

end
