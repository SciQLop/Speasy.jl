function Base.summarysize(var::T) where {T <: AbstractDataContainer}
    sz = @py2jl var.nbytes
    for field in fieldnames(T)
        sz += summarysize(getfield(var, field))
    end
    return sz
end

columns(x) = @py2jl x.columns
coord(var) = getmeta(var, "COORDINATE_SYSTEM")

# Calls `f` on an alias of the numpy memory that Julia indexes in memory order. Indexing the `PyArray` is
# slower, and strided for row-major data. Other layouts (non-contiguous numpy views) go behind a barrier,
# as compiling `f` for a `PyArray` is costly.
function _with_native(f, A::PyArray{T, N, M, L, T}) where {T, N, M, L}
    sz = size(A)
    GC.@preserve A begin
        strides(A) == Base.size_to_strides(1, sz...) && return f(unsafe_wrap(Array, pointer(A), sz))
        if strides(A) == reverse(Base.size_to_strides(1, reverse(sz)...))
            return f(PermutedDimsArray(unsafe_wrap(Array, pointer(A), reverse(sz)), ntuple(i -> N - i + 1, N)))
        end
    end
    return f(Base.inferencebarrier(A))
end
_with_native(f, A) = f(A)

# Resolved on the variable: the alias has no time dimension to find `depend_1` by.
_dims(var, dims) = something(dims, SpaceDataModel.depend_1_dimnum(var), 1)

function SpaceDataModel.mask_invalid(var::SpeasyVariable, c::ValidityChecks, dims = nothing)
    d = _dims(var, dims)
    return @set var.data = _with_native(A -> mask_invalid(A, c, d), parent(var))
end

# Float data are masked in place; integer data become a float copy.
function _sanitize(var)
    T = eltype(var)
    T <: Real || return var
    c = ValidityChecks(var)
    _haschecks(c) || return var
    T <: AbstractFloat || return mask_invalid(var, c)
    d = _dims(var, nothing)
    _with_native(A -> mask_invalid!(A, A, c, d), parent(var))
    return var
end

# Absent checks are SpaceDataModel's never-matching sentinels.
_haschecks(c::ValidityChecks{C}) where {C} =
    any(!isnan, c.fillval) || any(>(typemin(C)), c.validmin) || any(<(typemax(C)), c.validmax)

# _sanitize is more performant than pysanitize, so we make `drop_out_of_range_values` false by default
# https://github.com/SciQLop/speasy/issues/214 `drop_fill_values` is not supported
pysanitize(var::Py; drop_out_of_range_values = false, kw...) =
    var.sanitized(; drop_out_of_range_values, kw...)

isprovider(s) = Symbol(s) in (:amda, :cda, :csa, :ssc, :archive)
contain_provider(s::String) = first(eachsplit(s, "/")) in ("amda", "cda", "csa", "ssc", "archive")
isspectrogram(var) = getmeta(var, "DISPLAY_TYPE") == "spectrogram"

# https://github.com/SciQLop/speasy/discussions/156
# Design note: time series of scalar type also have `N=1`
isscalar(var) = false
isscalar(var::AbstractMatrix) = size(var, 2) == 1

# Row-major numpy data reach SpaceDataModel's masking as `PermutedDimsArray`s (see `_with_native`), which
# SpaceDataModel does not precompile. Python is not loaded while precompiling.
function _workload()
    for T in (Float32, Float64)
        mask_invalid(PermutedDimsArray(T[1 2; 3 4], (2, 1)), ValidityChecks(T, T(1), [T(0), T(0)], T(3)), 2)
    end
    return
end
ccall(:jl_generating_output, Cint, ()) == 1 && _workload()
