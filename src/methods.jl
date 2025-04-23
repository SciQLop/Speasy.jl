function Base.summarysize(var::T) where T<:AbstractDataContainer
    sz = pyconvert(Int64, var.py."nbytes")
    for field in fieldnames(T)
        sz += summarysize(getfield(var, field))
    end
    return sz
end

columns(x::Py) = pyconvert(Any, x."columns")
columns(x::AbstractDataContainer) = columns(x.py)
fill_value(var) = pyconvert(Any, var.py."fill_value")
valid_min(var) = pyconvert(Any, var.py."meta"["VALIDMIN"])
valid_max(var) = pyconvert(Any, var.py."meta"["VALIDMAX"])

function replace_fillval_by_nan(var)
    if eltype(var) <: Integer
        return var
    else
        return SpeasyVariable(var.py.replace_fillval_by_nan())
    end
end
replace_fillval_by_nan!(var) = (var.py.replace_fillval_by_nan(inplace=true); var)
pysanitize!(var; kwargs...) = (var.py.sanitized(; inplace=true, kwargs...); var)
sanitize(::Type{T}, var; kwargs...) where {T<:AbstractDataContainer} = T(var.py.sanitized(; kwargs...))

function sanitize!(var; replace_invalid=true, kwargs...)
    v = parent(var)
    # Replace values outside valid range with NaN
    if replace_invalid
        vmins = valid_min(var)
        vmaxs = valid_max(var)
        m = size(v, 2)
        # Apply filtering per column with matching vmins/vmaxs values (Handle case where vmins/vmaxs contain only one value)
        for i in 1:m
            vmin = @something get(vmins, i, nothing) only(vmins)
            vmax = @something get(vmaxs, i, nothing) only(vmaxs)
            vc = @view v[:, i]
            vc[(vc.<vmin).|(vc.>vmax)] .= NaN
        end
    end
    # Also replace fill values with NaN
    replace!(v, (fill_value(var) .=> NaN)...)
    return var
end

contain_provider(s::String) = length(split(s, "/")) == 3
isspectrogram(var) = get(var.meta, "DISPLAY_TYPE", nothing) == "spectrogram"

# https://github.com/SciQLop/speasy/discussions/156
# Design note: time series of scalar type also have `N=1`
isscalar(var) = false
isscalar(var::AbstractMatrix) = size(var, 2) == 1
scalarify(x) = x
scalarify(x::AbstractMatrix) = isscalar(x) ? vec(x) : x

standardize(v; kwargs...) = scalarify(sanitize(v; kwargs...))

function Unitful.unit(var::AbstractDataContainer)
    u_str = units(var)
    try
        return uparse(u_str)
    catch
    end
    try # replace space by *
        u_str = replace(u_str, " " => "*", "{" => "", "}" => "", "#" => "1", "sec" => "s", "cm3" => "cm^3")
        return uparse(u_str)
    catch
    end
    try # split str by space
        return uparse(split(u_str, " ")[1])
    catch
    end

    @info "Cannot parse $(name(var)) unit $u_str"
    return 1
end
