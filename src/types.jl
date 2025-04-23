abstract type AbstractDataContainer{T,N} <: AbstractDataVariable{T,N} end
abstract type AbstractSupportDataContainer{T,N} <: AbstractDataContainer{T,N} end

"""
A wrapper of `speasy.SpeasyVariable`.
"""
struct SpeasyVariable{T,N} <: AbstractDataContainer{T,N}
    py::Py
    data::PyArray{T,N}
    name::String
end

"""
A wrapper of `speasy.VariableAxis`.
https://github.com/SciQLop/speasy/blob/main/speasy/core/data_containers.py#L234
"""
struct VariableAxis{T,N} <: AbstractSupportDataContainer{T,N}
    py::Py
    data::PyArray{T,N}
    name::String
end

function (::Type{D})(py::Py) where {D<:AbstractDataContainer}
    data = PyArray(py."values", copy=false)
    T = eltype(data)
    N = ndims(data)
    return D{T,N}(py, data, pyconvert(String, py."name"))
end

isnone(var::AbstractDataContainer) = pyisnone(var.py)
Base.ismissing(var::AbstractDataContainer) = pyisnone(var.py)
PythonCall.PyArray(var::AbstractDataContainer; kwargs...) = PyArray(var.py."values"; kwargs...)

values(var) = var.py."values"
fill_value(var) = pyconvert(Any, var.py."fill_value")
valid_min(var) = pyconvert(Any, var.py."meta"["VALIDMIN"])
valid_max(var) = pyconvert(Any, var.py."meta"["VALIDMAX"])
Base.summarysize(var::AbstractDataContainer) = pyconvert(Int64, var.py."nbytes")
time(var) = pyconvert_time(var.py."time")
SpaceDataModel.times(var::AbstractDataContainer) = pyconvert_time(var.py."time")
axes(var, i) = VariableAxis(var.py."axes"[i-1])
axes(var) = [axes(var, i) for i in 1:pylen(var.py."axes")]
columns(var) = pyconvert(Vector{Symbol}, var.py."columns")
meta(var) = pyconvert(Dict, var.py."meta")
function SpaceDataModel.units(var::AbstractDataContainer)
    isnone(var) && return ""
    u = var.py."unit"
    pyisnone(u) ? "" : pyconvert(String, u)
end
coord(var) = pyconvert(String, var.py."meta"["COORDINATE_SYSTEM"])

func_properties(::Type{<:SpeasyVariable}) = (:values, :time, :columns, :meta, :units, :axes)

function getproperty(var::T, s::Symbol) where {T<:AbstractDataContainer}
    s in fieldnames(T) && return getfield(var, s)
    s in func_properties(T) && return eval(s)(var)
    return getproperty(var.py, s)
end

propertynames(::T) where {T<:AbstractDataContainer} = union(fieldnames(T), func_properties(T))

func_properties(::Type{<:VariableAxis}) = (:values, :units, :meta)

function values(ax::VariableAxis)
    ax.name == "time" ? pyconvert_time(ax.py.values) : pyconvert(Array, ax.py.values)
end