function replace_fillval_by_nan(var)
    if eltype(var) <: Integer
        return var
    else
        return SpeasyVariable(var.py.replace_fillval_by_nan())
    end
end
replace_fillval_by_nan!(var) = (var.py.replace_fillval_by_nan(inplace=true); var)
sanitize!(var; kwargs...) = (var.py.sanitized(; inplace=true, kwargs...); var)
sanitize(::Type{T}, var; kwargs...) where {T<:AbstractDataContainer} = T(var.py.sanitized(; kwargs...))

function sanitize(var; replace_invalid=true, kwargs...)
    v = PyArray(var)
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
    return v
end

contain_provider(s::String) = length(split(s, "/")) == 3
isspectrogram(var) = get(var.meta, "DISPLAY_TYPE", nothing) == "spectrogram"

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
