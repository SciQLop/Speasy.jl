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

function Base.similar(A::AbstractDataContainer, ::Type{S}, dims::Dims) where {S}
    return @set A.data = similar(A.data, S, dims)
end

"""
    SpeasyVariable(py; layout = :julia)

Wrap `speasy.SpeasyVariable` `py` without copying its values. With `layout = :julia`, time is the last dimension and
dimension `i` is `DEPEND_i`; time-varying axes are time-last too.
`layout = :python` keeps numpy's dimension order, time first.
"""
function SpeasyVariable(py::Py; layout = :julia)
    data = pyarray(@py(py.values), layout)
    axes = @py py.axes
    len = length(axes)
    N = ndims(data)
    dims = ntuple(N) do i
        a = layout === :julia ? mod(i, N) : i - 1 # numpy axis
        a < len ? VariableAxis(axes[a]; layout) : (1:size(data, i))
    end
    metadata = OverlayDict{Union{String, Symbol}, Any}(_pymeta(py))
    return SpeasyVariable(py, data, dims, py_name(py), metadata)
end

_pymeta(py::Py) = PyDict{String, Any}(@py py.meta)

# Time is last (`layout = :julia`) or first (`:python`); slicing may have dropped it.
function SpaceDataModel.tdimnum(var::SpeasyVariable)
    N = ndims(var)
    istime(i) = eltype(var.dims[i]) <: AbstractDateTime
    return istime(N) ? N : istime(1) ? 1 : nothing
end

"""
A wrapper of `speasy.VariableAxis`.
https://github.com/SciQLop/speasy/blob/main/speasy/core/data_containers.py#L234
"""
@concrete struct VariableAxis{T, N, A <: AbstractArray{T, N}} <: AbstractSupportDataContainer{T, N}
    py::Py
    data::A
end

VariableAxis(py::Py; layout = :julia) = VariableAxis(py, py2jlvalues(py; layout))

py_name(py::Py) = pyconvert(String, @py py.name)

SpaceDataModel.getmeta(var::AbstractSupportDataContainer) = _pymeta(var.py)
SpaceDataModel.name(var::AbstractSupportDataContainer) = py_name(var.py)
SpaceDataModel.timedim(var::AbstractSupportDataContainer{T}) where T = T <: AbstractTime ? var : nothing

PythonCall.Py(var::AbstractDataContainer) = var.py
function SpaceDataModel.units(var::AbstractDataContainer)
    py = var.py
    u = @py py.unit
    return pyisnone(u) ? "" : pyconvert(Any, u)
end

function Base.getproperty(var::T, s::Symbol) where {T <: AbstractDataContainer}
    return s in fieldnames(T) ? getfield(var, s) : getproperty(var.py, s)
end
