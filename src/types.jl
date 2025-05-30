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
    metadata::PyDict
end

function SpeasyVariable(py::Py)
    data = PyArray(py."values", copy=false)
    # time is stored as (converted to) a `Array` instead of `PyArray` (as `PyArray` cannot convert this Python `ndarray`).
    dims = (pyconvert_time(py."time"), columns(py))
    metadata = pyconvert(Any, py."meta")
    return SpeasyVariable(py, data, dims, pyconvert(String, py."name"), metadata)
end

"""
A wrapper of `speasy.VariableAxis`.
https://github.com/SciQLop/speasy/blob/main/speasy/core/data_containers.py#L234
"""
struct VariableAxis{T,N} <: AbstractSupportDataContainer{T,N}
    py::Py
    data::PyArray{T,N}
    name::String
    metadata::PyDict
end

function VariableAxis(py::Py)
    data = PyArray(py."values", copy=false)
    return VariableAxis(py, data, pyconvert(String, py."name"), pyconvert(Any, py."meta"))
end

PythonCall.Py(var::AbstractDataContainer) = var.py
SpaceDataModel.times(var::SpeasyVariable) = var.dims[1]
function SpaceDataModel.units(var::AbstractDataContainer)
    u = var.py."unit"
    pyisnone(u) ? "" : pyconvert(Any, u)
end

function Base.getproperty(var::T, s::Symbol) where {T<:AbstractDataContainer}
    s in fieldnames(T) ? getfield(var, s) : getproperty(var.py, s)
end
