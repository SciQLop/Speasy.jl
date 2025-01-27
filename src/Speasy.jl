module Speasy

using PythonCall
using Dates
import Base: getproperty, propertynames

export speasy, SpeasyVariable
export get_data
export replace_fillval_by_nan, replace_fillval_by_nan!, sanitize, sanitize!

include("utils.jl")
include("methods.jl")

const speasy = PythonCall.pynew()

function __init__()
    println("Initializing speasy...")
    PythonCall.pycopy!(speasy, pyimport("speasy"))
end

"""
A wrapper of `speasy.SpeasyVariable`.
"""
struct SpeasyVariable
    py::Py
end

function get_data(args...)
    res = speasy.get_data(args...)
    return apply_recursively(res, SpeasyVariable, is_pylist)
end

values(var) = pyconvert(Array, var.py.values)
time(var) = pyconvert_time(var.py.time)
columns(var) = pyconvert(Vector{Symbol}, var.py.columns)
meta(var) = pyconvert(Dict, var.py.meta)
units(var) = pyconvert(String, var.py.unit)

const speasy_properties = (:values, :time, :columns, :meta, :units)

function getproperty(var::SpeasyVariable, s::Symbol)
    s in fieldnames(SpeasyVariable) && return getfield(var, s)
    s in speasy_properties && return eval(s)(var)
end

propertynames(var::SpeasyVariable) = union(fieldnames(SpeasyVariable), speasy_properties)
end
