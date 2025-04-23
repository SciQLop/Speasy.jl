abstract type AbstractDataContainer{T,N} <: AbstractDataVariable{T,N} end
abstract type AbstractSupportDataContainer{T,N} <: AbstractDataContainer{T,N} end

"""
A wrapper of `speasy.SpeasyVariable`.
"""
struct SpeasyVariable{T,N,D<:Tuple} <: AbstractDataContainer{T,N}
    py::Py
    data::PyArray{T,N}
    dims::D
    name::String
end

function SpeasyVariable(py::Py)
    data = PyArray(py."values", copy=false)
    # time is stored as (converted to) a `Array` instead of `PyArray` (as `PyArray` cannot convert this Python `ndarray`).
    dims = (pyconvert_time(py."time"), pyconvert(Any, py."columns"))
    return SpeasyVariable(py, data, dims, pyconvert(String, py."name"))
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

function VariableAxis(py::Py)
    data = PyArray(py."values", copy=false)
    return VariableAxis(py, data, pyconvert(String, py."name"))
end

isnone(var::AbstractDataContainer) = pyisnone(var.py)
Base.ismissing(var::AbstractDataContainer) = pyisnone(var.py)
SpaceDataModel.meta(var::AbstractDataContainer) = pyconvert(Dict, var.py."meta")
SpaceDataModel.times(var::AbstractDataContainer) = var.dims[1]
function SpaceDataModel.units(var::AbstractDataContainer)
    isnone(var) && return ""
    u = var.py."unit"
    pyisnone(u) ? "" : pyconvert(String, u)
end
coord(var) = pyconvert(String, var.py."meta"["COORDINATE_SYSTEM"])

function getproperty(var::T, s::Symbol) where {T<:AbstractDataContainer}
    s in fieldnames(T) && return getfield(var, s)
    return getproperty(var.py, s)
end