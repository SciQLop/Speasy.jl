"""
    pyconvert_time(times)

Convert `times` from Python to Julia.

Much faster than `pyconvert(Array, times)`
"""
function pyconvert_time(times)
    len = length(times)
    len == 0 && return UnixTime[]
    py_ns = PyArray{Int64, 1, true, true, Int64}(@py times.view("i8"); copy = false)
    return reinterpret(UnixTime, py_ns)
end

function py2jlvalues(var; copy = false)
    py = @py var.values
    # Check if the array has byte string dtype (e.g., '|S22')
    dtype = @py py.dtype
    dtype_num = pyconvert(Int, @py dtype.num)
    dtype_num == 21 && return pyconvert_time(py) # datetime64[ns]
    valid_py = if dtype_num == 18 # string dtype 'S'
        @py py.astype("U") # Convert byte strings to Unicode strings in Python first
    elseif dtype_num == 20 # Structured dtype like [('value', '<i8')]
        view_dtype = field_dtype(dtype)
        @py py.view(view_dtype)
    else
        py
    end
    return PyArray(valid_py; copy)
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
    return quote
        if haskey($(esc(dict)), $(esc(key)))
            $(esc(dict))[$(esc(key))] = $(esc(value))
        end
    end
end

"""
    OverlayDict{K,V}

A dictionary that overlays a mutable Dict on top of an immutable PyDict.
Key lookups first check the overlay, then fall back to the base PyDict.
All modifications only affect the overlay, leaving the base unchanged.

# Example
```julia
base = pydict(Dict("a" => 1, "b" => 2))
d = OverlayDict{String,Int}(base)
d["c"] = 3  # only modifies overlay
d["a"]      # returns 1 from base
d["c"]      # returns 3 from overlay
```
"""
struct OverlayDict{K, V} <: AbstractDict{K, V}
    base::Py
    overlay::Dict{K, V}
end

OverlayDict{K, V}(base::Py) where {K, V} = OverlayDict{K, V}(base, Dict{K, V}())

function Base.getindex(d::OverlayDict{K, V}, key) where {K, V}
    return get(d.overlay, key) do
        pyconvert(V, d.base[key])
    end
end

function Base.get(d::OverlayDict{K, V}, key, default) where {K, V}
    return get(d.overlay, key) do
        py = d.base
        haskey(py, key) ? pyconvert(V, py[key]) : default
    end
end

Base.setindex!(d::OverlayDict, value, key) = setindex!(d.overlay, value, key)
Base.haskey(d::OverlayDict, key) = haskey(d.overlay, key) || haskey(d.base, key)

function Base.keys(d::OverlayDict{K}) where {K}
    py = d.base
    return union(keys(d.overlay), pyconvert(Set{K}, @py py.keys()))
end

Base.length(d::OverlayDict) = length(keys(d))

function Base.iterate(d::OverlayDict{K, V}) where {K, V}
    ks = keys(d)
    iter_state = iterate(ks)
    isnothing(iter_state) && return nothing
    key, state = iter_state
    return (key => d[key], (ks, state))
end

function Base.iterate(d::OverlayDict{K, V}, (keys, state)) where {K, V}
    iter_state = iterate(keys, state)
    isnothing(iter_state) && return nothing
    key, new_state = iter_state
    return (key => d[key], (keys, new_state))
end
