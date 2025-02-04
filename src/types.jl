abstract type AbstractDataContainer end
abstract type AbstractSupportDataContainer <: AbstractDataContainer end

"""
A wrapper of `speasy.SpeasyVariable`.
"""
struct SpeasyVariable <: AbstractDataContainer
    py::Py
end

getindex(var::AbstractDataContainer, s::String) = SpeasyVariable(var.py[s])
getindex(var::AbstractDataContainer, s::Symbol) = getindex(var, string(s))

name(var) = pyconvert(String, var.py.name)
values(var) = pyconvert(Array, var.py.values)
time(var) = pyconvert_time(var.py.time)
axes(var, i) = VariableAxis(var.py.axes[i-1])
axes(var) = [axes(var, i) for i in 1:pylen(var.py.axes)]
columns(var) = pyconvert(Vector{Symbol}, var.py.columns)
meta(var) = pyconvert(Dict, var.py.meta)
units(var) = pyconvert(String, var.py.unit)
coord(var) = pyconvert(String, var.py.meta["COORDINATE_SYSTEM"])

const speasy_properties = (:name, :values, :time, :columns, :meta, :units, :axes)

function getproperty(var::SpeasyVariable, s::Symbol)
    s in (:py,) && return getfield(var, s)
    s in speasy_properties && return eval(s)(var)
    return getproperty(var.py, s)
end

propertynames(var::SpeasyVariable) = union(fieldnames(SpeasyVariable), speasy_properties)

"""
A wrapper of `speasy.VariableAxis`.
https://github.com/SciQLop/speasy/blob/main/speasy/core/data_containers.py#L229
"""
struct VariableAxis <: AbstractSupportDataContainer
    py::Py
end

ax_properties = (:name, :values, :units)

function values(ax::VariableAxis)
    ax.name == "time" ? pyconvert_time(ax.py.values) : pyconvert(Array, ax.py.values)
end


function getproperty(var::VariableAxis, s::Symbol)
    s in (:py,) && return getfield(var, s)
    s in ax_properties && return eval(s)(var)
    return getproperty(var.py, s)
end

propertynames(var::VariableAxis) = union(fieldnames(VariableAxis), ax_properties)
