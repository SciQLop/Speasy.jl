module SpeasyTimeSeriesExt

using Speasy
using Speasy: name, times, columns, getmeta, tdimnum
import TimeSeries
import TimeSeries: TimeArray

function TimeSeries.TimeArray(s::SpeasyVariable)
    colnames = columns(s)
    colnames = length(colnames) > 2 ? colnames : [name(s)] # conventional naming for scalar variables
    values = tdimnum(s) == 1 ? parent(s) : transpose(parent(s))
    return TimeArray(times(s), values, Symbol.(colnames), getmeta(s))
end
end