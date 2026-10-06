"""
    pyconvert_time(times)

Convert `times` from Python to Julia.

Much faster than `pyconvert(Array, times)`
"""
function pyconvert_time(times)
    len = length(times)
    len == 0 && return Timestamp{Nanosecond}[]
    py_ns = PyArray{Int64, 1, true, true, Int64}(@py times.view("i8"); copy = false)
    return reinterpret(Timestamp{Nanosecond}, py_ns)
end

function py2jlvalues(var; layout = :julia)
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
    return pyarray(valid_py, layout)
end

# numpy (t, D1, …, Dk), row-major, as Julia (D1, …, Dk, t) without copying. For k ≥ 2 the result is a
# `PermutedDimsArray` whose dimension 1 is not the fastest in memory, so generic loops stride; internal
# kernels (`_with_native`, `Array`) undo the permutation instead.
function pyarray(values::Py, layout)
    layout === :python && return PyArray(values; copy = false)
    layout === :julia || throw(ArgumentError("layout must be :julia or :python, got $(repr(layout))"))
    A = PyArray(@py(values.T); copy = false)
    N = ndims(A)
    return N <= 2 ? A : PermutedDimsArray(A, (ntuple(i -> N - i, N - 1)..., N))
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

_key_names(p) = nothing

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
