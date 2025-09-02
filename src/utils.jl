"""
    pyconvert_time(times)

Convert `times` from Python to Julia.

Much faster than `pyconvert(Array, times)`
"""
function pyconvert_time(times)
    len = length(times)
    len == 0 && return UnixTime[]
    py_ns = PyArray{Int64, 1, true, true, Int64}(times."view"("i8"), copy = false)
    return reinterpret(UnixTime, py_ns)
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

_key_names(p) = nothing
_key_names(p::AbstractDataSet) = keys(parameters(p))

_compat(arg) = string(arg)
_compat(arg::Py) = arg
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

"""
    @update! dict key value

If `key` exists in `dict`, assign `dict[key] = value`.
"""
macro update!(dict, key, value)
    quote
        if haskey($(esc(dict)), $(esc(key)))
            $(esc(dict))[$(esc(key))] = $(esc(value))
        end
    end
end