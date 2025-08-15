module SpeasyTimeSeriesExt

using Speasy
using Speasy: name, times, columns, meta
import TimeSeries: TimeArray

function TimeArray(s::SpeasyVariable)
    colnames = columns(s)
    colnames = length(colnames) > 2 ? colnames : [name(s)] # conventional naming for scalar variables
    return TimeArray(times(s), parent(s), colnames, meta(s))
end

TimeArray(v::AbstractArray{SpeasyVariable}) = merge(TimeArray.(v)...)
end