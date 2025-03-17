abstract type AbstractDataContainer{T,N} <: AbstractArray{T,N} end
abstract type AbstractSupportDataContainer{T,N} <: AbstractDataContainer{T,N} end

"""
A wrapper of `speasy.SpeasyVariable`.
"""
struct SpeasyVariable{T,N} <: AbstractDataContainer{T,N}
    py::Py
end

function SpeasyVariable(py::Py)
    T = dtype(py)
    N = length(py.shape)
    return SpeasyVariable{T,N}(py)
end

# Array Interface
# https://docs.julialang.org/en/v1/manual/interfaces/#man-interface-array
Base.size(var::AbstractDataContainer) = pyconvert(Tuple, var.py.shape)
Base.getindex(var::AbstractDataContainer, I::Vararg{Int,N}) where {N} = pyconvert(Any, getindex(var.py.values, (I .- 1)...))

Base.getindex(var::AbstractDataContainer, s::String) = SpeasyVariable(var.py[s])
Base.getindex(var::AbstractDataContainer, s::Symbol) = getindex(var, string(s))

isnone(var::AbstractDataContainer) = pyisnone(var.py)
Base.ismissing(var::AbstractDataContainer) = pyisnone(var.py)

function name(var)
    isnone(var) && return nothing
    pyconvert(String, var.py.name)
end
values(var) = PyArray(var.py.values)
fill_value(var) = pyconvert(Array, var.py.fill_value)
valid_min(var) = pyconvert(Array, var.py.meta["VALIDMIN"])
valid_max(var) = pyconvert(Array, var.py.meta["VALIDMAX"])
nbytes(var) = pyconvert(Int64, var.py.nbytes)
time(var) = pyconvert_time(var.py.time)
axes(var, i) = VariableAxis(var.py.axes[i-1])
axes(var) = [axes(var, i) for i in 1:pylen(var.py.axes)]
columns(var) = pyconvert(Vector{Symbol}, var.py.columns)
meta(var) = pyconvert(Dict, var.py.meta)
function units(var)
    isnone(var) && return ""
    u = var.py.unit
    pyisnone(u) ? "" : pyconvert(String, u)
end
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
struct VariableAxis{T,N} <: AbstractSupportDataContainer{T,N}
    py::Py
end

function VariableAxis(py::Py)
    T = dtype(py)
    N = length(pyconvert(Tuple, py.shape))
    return VariableAxis{T,N}(py)
end

ax_properties = (:name, :values, :units, :meta)

function values(ax::VariableAxis)
    ax.name == "time" ? pyconvert_time(ax.py.values) : pyconvert(Array, ax.py.values)
end


function getproperty(var::VariableAxis, s::Symbol)
    s in (:py,) && return getfield(var, s)
    s in ax_properties && return eval(s)(var)
    return getproperty(var.py, s)
end

propertynames(var::VariableAxis) = union(fieldnames(VariableAxis), ax_properties)

# https://github.com/rafaqz/DimensionalData.jl/blob/main/src/Dimensions/show.jl#L5
function colors(i)
    colors = [209, 32, 81, 204, 249, 166, 37]
    c = rem(i - 1, length(colors)) + 1
    colors[c]
end

print_name(io::IO, var) = printstyled(io, name(var); color=colors(7))

function Base.show(io::IO, var::T) where {T<:AbstractDataContainer}
    ismissing(var) && return
    print(io, "$T(")
    print_name(io, var)
    pyhasattr(var.py, "time") && print(io, ", Time Range: ", time(var)[1], " to ", time(var)[end])
    print(io, ", Units: ", var.py.unit)
    print(io, ", Shape: ", var.py.shape)
    print(io, ")")
end

# Add Base.show methods for pretty printing
function Base.show(io::IO, m::MIME"text/plain", var::T) where {T<:AbstractDataContainer}
    ismissing(var) && return
    print(io, "$T: ")
    print_name(io, var)
    println(io)
    pyhasattr(var.py, "time") && println(io, "  Time Range: ", time(var)[1], " to ", time(var)[end])
    println(io, "  Units: ", var.py.unit)
    println(io, "  Shape: ", var.py.shape)
    println(io, "  Size: ", Base.format_bytes(nbytes(var)))
    pyhasattr(var.py, "columns") && println(io, "  Columns: ", var.py.columns)
    if pyhasattr(var.py, "meta")
        println(io, "  Metadata:")
        for (key, value) in sort(collect(meta(var)), by=x -> x[1])
            println(io, "    ", key, ": ", value)
        end
    end
end