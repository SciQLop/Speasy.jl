get_provider(s) = nothing
get_provider(s::String) = first(eachsplit(s, "/"))

function general_get_data(prod::String, t0, t1; drop_nan=false, sanitize=false)
    v = speasy_get_data(_compat(prod), _compat(t0), _compat(t1))
    pyisnone(v) && return nothing
    drop_nan && (v = py_drop_nan(v))
    sanitize && (v = pysanitize(v))
    SpeasyVariable(v)
end

function general_get_data(args...; drop_nan=false, sanitize=false)
    v = speasy_get_data(_compat.(args)...)
    pyisnone(v) && return nothing
    drop_nan && (v = apply_recursively(v, py_drop_nan, is_pylist))
    sanitize && (v = apply_recursively(v, pysanitize, is_pylist))
    apply_recursively(v, SpeasyVariable, is_pylist)
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
    pyisnone(v) ? nothing : SpeasyVariable(v)
end
