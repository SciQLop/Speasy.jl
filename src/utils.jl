"""
    pyconvert_time(time)

Convert `time` from Python to Julia.

Much faster than `pyconvert(Array, time)`
"""
function pyconvert_time(time)
    pydt_min = @pyconst(pyimport("numpy").timedelta64(1, "ns"))
    dt_min = Nanosecond(1)
    pyt0 = time[0]
    # t0 = pyconvert(DateTime, pyt0.astype("datetime64[us]").item())
    t0 = pyconvert(DateTime, pyt0)
    dt_f = pyconvert(Array, (time - pyt0) / pydt_min)
    return t0 .+ dt_f .* dt_min
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