function Base.summarysize(var::T) where {T <: AbstractDataContainer}
    sz = @py2jl var.nbytes
    for field in fieldnames(T)
        sz += summarysize(getfield(var, field))
    end
    return sz
end

columns(x) = @py2jl x.columns
fill_value(var) = @py2jl var.fill_value
coord(var) = get(var, "COORDINATE_SYSTEM")
valid_min(var) = get(var, "VALIDMIN", nothing)
valid_max(var) = get(var, "VALIDMAX", nothing)

# this makes `fill_value`, `vmins` and `vmaxs` of same type, which makes the code faster
@inline vec_T(T, vs::AbstractVector) = Base.convert(Vector{T}, vs)
@inline vec_T(T, vs) = T[vs]

# https://github.com/SciQLop/speasy/blob/7baf7366513771bcde85d90af560475c53a93ea0/speasy/products/variable.py#L703
"""Replaces fill values by NaN for `var` with float type elements."""
function replace_fillval_by_nan!(var; verbose = false)
    T = eltype(var)
    if T <: AbstractFloat
        val = fill_value(var)
        if !isnothing(val) && !all(isnan, val)
            replace!(parent(var), (vec_T(T, val) .=> T(NaN))...)
        end
    else
        verbose && @warn "Cannot replace fill values for $(name(var)) of type $T"
    end
    return var
end

function replace_invalid!(A::AbstractMatrix, vmins, vmaxs)
    T = eltype(A)
    for i in axes(A, 2)
        vmin = get(vmins, i, vmins[1])
        vmax = get(vmaxs, i, vmaxs[1])
        vc = @view A[:, i]
        @. vc = ifelse((vc < vmin) | (vc > vmax), T(NaN), vc)
    end
    return A
end

function replace_invalid!(A::AbstractArray{T}, valid_mins, valid_maxs) where {T}
    isnothing(valid_mins) && return A
    isnothing(valid_maxs) && return A
    vmin = T(only(valid_mins))
    vmax = T(only(valid_maxs))
    nan = T(NaN)
    return @. A = ifelse((A < vmin) | (A > vmax), nan, A)
end

"""Replaces invalid values by NaN for `var` with float type elements."""
function replace_invalid!(var; verbose = false)
    T = eltype(var)
    if T <: AbstractFloat
        vmins = valid_min(var)
        vmaxs = valid_max(var)
        if !isnothing(vmins) && !isnothing(vmaxs)
            replace_invalid!(parent(var), vec_T(T, vmins), vec_T(T, vmaxs))
        end
    else
        verbose && @warn "Cannot replace invalid values for $(name(var)) of type $T"
    end
    return var
end

# sanitize! is more performant than pysanitize, so we make `drop_out_of_range_values` false by default
# https://github.com/SciQLop/speasy/issues/214 `drop_fill_values` is not supported
pysanitize(var::Py; drop_out_of_range_values = false, kw...) =
    var.sanitized(; drop_out_of_range_values, kw...)

"""
Replaces invalid values and fill values by NaN for `var` with float type elements.
"""
function sanitize!(var; replace_invalid = true, replace_fillval = true, verbose = false, kwargs...)
    replace_invalid && replace_invalid!(var; verbose)
    replace_fillval && replace_fillval_by_nan!(var; verbose)
    return var
end

isprovider(s) = Symbol(s) in (:amda, :cda, :csa, :ssc, :archive)
contain_provider(s::String) = first(eachsplit(s, "/")) in ("amda", "cda", "csa", "ssc", "archive")
isspectrogram(var) = get(var, "DISPLAY_TYPE") == "spectrogram"

# https://github.com/SciQLop/speasy/discussions/156
# Design note: time series of scalar type also have `N=1`
isscalar(var) = false
isscalar(var::AbstractMatrix) = size(var, 2) == 1
