replace_fillval_by_nan(var) = SpeasyVariable(var.py.replace_fillval_by_nan())
replace_fillval_by_nan!(var) = (var.py.replace_fillval_by_nan(inplace=true); var)
sanitize!(var; kwargs...) = (var.py.sanitized(; inplace=true, kwargs...); var)
sanitize(var; kwargs...) = SpeasyVariable(var.py.sanitized(; kwargs...))

isspectrogram(var) = get(var.meta, "DISPLAY_TYPE", nothing) == "spectrogram"

function Unitful.unit(var::AbstractDataContainer)
    u_str = units(var)
    try
        return uparse(u_str)
    catch
    end
    try # replace space by *
        return uparse(replace(u_str, " " => "*"))
    catch
    end
    try # split str by space
        return uparse(split(u_str, " ")[1])
    catch
    end

    @info "Cannot parse unit $u_str"
    return 1
end
