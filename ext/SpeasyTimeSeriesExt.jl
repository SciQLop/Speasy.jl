module SpeasyTimeSeriesExt

using Speasy
using Speasy: name, times, columns, meta
import TimeSeries
import TimeSeries: TimeArray

function TimeSeries.TimeArray(s::SpeasyVariable)
    colnames = columns(s)
    colnames = length(colnames) > 2 ? colnames : [name(s)] # conventional naming for scalar variables
    return TimeArray(times(s), parent(s), Symbol.(colnames), meta(s))
end
end