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

isnone(var::AbstractDataContainer) = pyisnone(var.py)
Base.ismissing(var::AbstractDataContainer) = pyisnone(var.py)

function name(var)
    isnone(var) && return nothing
    pyconvert(String, var.py.name)
end
values(var) = pyconvert(Array, var.py.values)
fill_value(var) = var.py.fill_value
valid_min(var) = pyconvert(Array, var.py.meta["VALIDMIN"])
valid_max(var) = pyconvert(Array, var.py.meta["VALIDMAX"])
shape(var) = pyconvert(Tuple, var.py.shape)
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
struct VariableAxis <: AbstractSupportDataContainer
    py::Py
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

function Base.show(io::IO, var::T) where {T<:AbstractDataContainer}
    ismissing(var) && return
    println(io, "$T(")
    print(io, "  Name: ", name(var))
    pyhasattr(var.py, "time") && println(io, "  Time Range: ", time(var)[1], " to ", time(var)[end])
    print(io, "  Units: ", var.py.unit)
    print(io, "  Shape: ", var.py.shape)
    print(io, "  Values: ")
    print(io, var.py.values)
    println(io, ")")
end

# Add Base.show methods for pretty printing
function Base.show(io::IO, m::MIME"text/plain", var::T) where {T<:AbstractDataContainer}
    ismissing(var) && return
    println(io, "$T:")
    println(io, "  Name: ", name(var))
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