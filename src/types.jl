abstract type AbstractDataContainer{T, N} <: AbstractDataVariable{T, N} end
abstract type AbstractSupportDataContainer{T, N} <: AbstractDataContainer{T, N} end

"""A wrapper of `speasy.SpeasyVariable`."""
@concrete struct SpeasyVariable{T, N, A <: AbstractArray{T, N}} <: AbstractDataContainer{T, N}
    py::Py
    data::A
    dims
    name
    metadata
end

function Base.show(io::IO, T::Type{<:AbstractDataContainer})
    return print(io, "$(nameof(T)){$(eltype(T)), $(ndims(T))}")
end

function Base.similar(A::AbstractDataContainer, ::Type{S}, dims::Dims) where {S}
    return @set A.data = similar(A.data, S, dims)
end

function SpeasyVariable(py::Py)
    data = PyArray(@py(py.values), copy = false)
    axes = @py py.axes
    len = length(axes)
    dims = ntuple(ndims(data)) do i
        i <= len ? VariableAxis(axes[i - 1]) : (1:size(data, i))
    end
    metadata = pyconvert(Dict{Union{String, Symbol}, Any}, @py(py.meta))
    return SpeasyVariable(py, data, dims, py_name(py), metadata)
end

"""
A wrapper of `speasy.VariableAxis`.
https://github.com/SciQLop/speasy/blob/main/speasy/core/data_containers.py#L234
"""
@concrete struct VariableAxis{T, N, A <: AbstractArray{T, N}} <: AbstractSupportDataContainer{T, N}
    py::Py
    data::A
end

function VariableAxis(py::Py)
    data = py2jlvalues(py)
    return VariableAxis(py, data)
end

py_name(py::Py) = pyconvert(String, @py py.name)

SpaceDataModel.meta(var::AbstractSupportDataContainer) = pyconvert(PyDict{Any, Any}, var.py."meta")
SpaceDataModel.name(var::AbstractSupportDataContainer) = py_name(var.py)

PythonCall.Py(var::AbstractDataContainer) = var.py
SpaceDataModel.times(var::SpeasyVariable) = var.dims[1]
function SpaceDataModel.units(var::AbstractDataContainer)
    py = var.py
    u = @py py.unit
    return pyisnone(u) ? "" : pyconvert(Any, u)
end

function Base.getproperty(var::T, s::Symbol) where {T <: AbstractDataContainer}
    s in fieldnames(T) && return getfield(var, s)
    return getproperty(var.py, s)
end
