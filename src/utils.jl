"""
    pyconvert_time(time)

Convert `time` from Python to Julia.

Much faster than `pyconvert(Array, time)`
"""
function pyconvert_time(time)
    pyus = @pyconst(pyimport("numpy").timedelta64(1, "us"))
    pt0 = time[0]
    t0 = pyconvert(DateTime, pt0.astype("datetime64[us]").item())
    dt = pyconvert(Array, (time - pt0) / pyus)
    return t0 .+ dt .* Microsecond(1)
end