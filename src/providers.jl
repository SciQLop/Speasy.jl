get_provider(_) = nothing
get_provider(s::String) = first(eachsplit(s, "/"))

function general_get_data(prod::String, t0, t1; drop_nan = false, sanitize = true, kw...)
    v = speasy_get_data(_compat(prod), _compat(t0), _compat(t1); kw...)
    pyisnone(v) && return nothing
    drop_nan && (v = py_drop_nan(v))
    var = SpeasyVariable(v)
    sanitize && sanitize!(var)
    return var
end

function general_get_data(args...; drop_nan = false, sanitize = true, kw...)
    v = speasy_get_data(_compat.(args)...; kw...)
    pyisnone(v) && return nothing
    drop_nan && (v = apply_recursively(v, py_drop_nan, is_pylist))
    vars = apply_recursively(v, x -> pyisnone(x) ? nothing : SpeasyVariable(x), is_pylist)
    sanitize && apply_recursively(vars, sanitize!, x -> !isnothing(x) && !(eltype(x) <: Number))
    return vars
end

"""
    ssc_get_data(args...)

Get data from [Satellite Situation Center (SSCWeb)](https://sscweb.gsfc.nasa.gov/).

Compare to `get_data`, this function support `coord` as the last argument.
The following coordinates systems are available: geo, gm, gse, gsm, sm, geitod, geij2000.
By default `gse` is used.

Reference: [Speasy Documentation](https://speasy.readthedocs.io/en/latest/user/sscweb/sscweb.html)
"""
function ssc_get_data(args...)
    v = @pyconst(speasy.ssc.get_data)(_compat.(args)...)
    return pyisnone(v) ? nothing : SpeasyVariable(v)
end
