replace_fillval_by_nan(var) = SpeasyVariable(var.py.replace_fillval_by_nan())
replace_fillval_by_nan!(var) = (var.py.replace_fillval_by_nan(inplace=true); var)
sanitize!(var; kwargs...) = (var.py.sanitized(; inplace=true, kwargs...); var)
sanitize(var; kwargs...) = SpeasyVariable(var.py.sanitized(; kwargs...))
