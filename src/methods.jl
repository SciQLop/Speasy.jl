Base.iterate(var::AbstractDataContainer, state=1) = state > length(var) ? nothing : (var[state], state + 1)

Base.Array(var::AbstractDataContainer) = pyconvert(Array, var.py.values)

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
    v = Array(var)
    # Replace values outside valid range with NaN
    if replace_invalid
        vmins = valid_min(var)
        vmaxs = valid_max(var)
        # Apply filtering per column for each value in vmins/vmaxs
        for i in eachindex(vmins)
            vmin = vmins[i]
            vmax = vmaxs[i]
            v[(v[:, i].<vmin).|(v[:, i].>vmax), i] .= NaN
        end
    end
    # Also replace fill values with NaN
    replace!(v, (fill_value(var) .=> NaN)...)
    return v
end

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
