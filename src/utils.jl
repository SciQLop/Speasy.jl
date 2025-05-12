using StatsBase: median

# temporary solution, related to https://github.com/JuliaPy/PythonCall.jl/pull/509
convert_time(::Type{<:DateTime}, t::Py) = DateTime(pyconvert(String, pystr(t.astype("datetime64[ms]")))) # pyconvert(DateTime, pyt0.astype("datetime64[ms]").item()) # slower
convert_time(::Type{<:NanoDate}, t::Py) = NanoDate(pyconvert(String, pystr(t)))

py_drop_nan(x) = x[np.isfinite(x).reshape(-1)]

"""
    pyconvert_time(times)

Convert `times` from Python to Julia.

It automatically choose the time type based on the time resolution.

Much faster than `pyconvert(Array, times)`
"""
function pyconvert_time(times; N=1000)
    if length(times) == 0
        return DateTime[]
    end
    dt_min = Nanosecond(1)
    pyt0 = times[0]
    dt_f = PyArray((times - pyt0) / pyns, copy=false)
    dt_med = median(length(dt_f) > N ? view(dt_f, 1:N) : dt_f)
    tType = dt_med > 1e7 ? DateTime : NanoDate
    t0 = convert_time(tType, pyt0)

    map(dt_f) do dt
        !isnan(dt) ? t0 + dt * dt_min : missing
    end
end

is_pylist(x) = pyisinstance(x, pybuiltins.list)

function apply_recursively(data, apply_fn, check_fn)
    if check_fn(data)
        return map(data) do x
            apply_recursively(x, apply_fn, check_fn)
        end
    else
        return apply_fn(data)
    end
end

@enum Vartype begin
    data
    support_data
    metadata
end

"Convert a string to Vartype"
function vartype(s::String)
    s == "data" && return data
    s == "support_data" && return support_data
    s == "metadata" && return metadata
    throw(ArgumentError("Invalid Vartype: $s"))
end

vartype(var) = vartype(var.meta["VAR_TYPE"])

dtype(x) = dtype2type(string(x."dtype"."name"))

function dtype2type(dtype::String)
    if dtype == "float16"
        Float16
    elseif dtype == "float32"
        Float32
    elseif dtype == "float64"
        Float64
    elseif dtype == "int8"
        Int8
    elseif dtype == "int16"
        Int16
    elseif dtype == "int32"
        Int32
    elseif dtype == "int64"
        Int64
    elseif dtype == "uint8"
        UInt8
    elseif dtype == "uint16"
        UInt16
    elseif dtype == "uint32"
        UInt32
    elseif dtype == "uint64"
        UInt64
    elseif dtype == "bool"
        Bool
    elseif dtype == "datetime64[ns]"
        DateTime
    else
        error("Unsupported dtype: '$dtype'")
    end
end

_key_names(p) = keys(p)
_key_names(p::AbstractDataSet) = keys(parameters(p))
_key_names(p::AbstractArray) = nothing

_compat(arg) = arg
_compat(arg::AbstractDateTime) = string(arg) # Support NanoDates
_compat(arg::AbstractVector) = _compat.(arg)
_compat(arg::NTuple{2}) = collect(_compat.(arg))

"""Get the property of `var.py` and convert it to Julia."""
py2jl_getproperty(py::Py, s) = pyconvert(Any, getproperty(py, s))
py2jl_getproperty(var, s) = py2jl_getproperty(Py(var), s)

# Macro to shorthand @py2jl x.field → py2jl_getproperty(x, :field)
macro py2jl(expr)
    obj = expr.args[1]
    field = expr.args[2]
    return :(py2jl_getproperty($(esc(obj)), $(field)))
end
