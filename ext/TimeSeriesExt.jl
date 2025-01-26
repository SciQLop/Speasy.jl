module TimeSeriesExt

using Speasy
using Speasy: time, values, columns, meta
import TimeSeries: TimeArray

function TimeArray(s::SpeasyVariable)
    return TimeArray(time(s), values(s), columns(s), meta(s))
end

end