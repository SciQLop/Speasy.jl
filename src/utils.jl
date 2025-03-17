"""
    pyconvert_time(time)

Convert `time` from Python to Julia.

Much faster than `pyconvert(Array, time)`
"""
function pyconvert_time(time)
    if length(time) == 0
        return DateTime[]
    end
    pydt_min = pyimport("numpy").timedelta64(1, "ns")
    dt_min = Nanosecond(1)
    pyt0 = time[0]
    # t0 = pyconvert(DateTime, pyt0.astype("datetime64[s]").item()) # temporary solution, related to https://github.com/JuliaPy/PythonCall.jl/pull/509
    t0 = NanoDate(pyconvert(String, pystr(pyt0))) # temporary solution, related to https://github.com/JuliaPy/PythonCall.jl/pull/509
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

dtype(x) = dtype2type(string(x.dtype.name))

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