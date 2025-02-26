module SpeasyTimeSeriesExt

using Speasy
using Speasy: name, time, values, columns, meta
import TimeSeries: TimeArray

function TimeArray(s::SpeasyVariable)
    colnames = columns(s)
    colnames = length(colnames) > 2 ? colnames : [name(s)] # conventional naming for scalar variables
    return TimeArray(time(s), values(s), colnames, meta(s))
end

TimeArray(v::AbstractArray{SpeasyVariable}) = merge(TimeArray.(v)...)
end