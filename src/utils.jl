# Typed `PyArray` over an int64 view: untyped `PyArray` rejects datetime64 in its `__array_struct__` path
# and falls back through a caught exception, orders of magnitude slower.
function pyconvert_time(times)
    ns = @py times.astype("datetime64[ns]", copy = False).view("i8")
    return reinterpret(Timestamp{Nanosecond}, PyArray{Int64, 1, true, true, Int64}(ns; copy = false))
end

function py2jlvalues(var; layout = :julia)
    py = @py var.values
    kind = pyconvert(Char, @py py.dtype.kind)
    kind == 'M' && return pyconvert_time(py)
    kind == 'S' && (py = @py py.astype("U")) # PyArray rejects byte strings
    return pyarray(py, layout)
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
