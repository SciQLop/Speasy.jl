module TimeseriesToolsExt
using TimeseriesTools
using Speasy
import TimeseriesTools: ToolsArray, TimeSeries

function TimeSeries(v::SpeasyVariable)
    name = Symbol(v.name)
    dims = (v.time, Dim{name}(v.columns))
    TimeseriesTools.TimeSeries(dims..., v.values; name, metadata=v.meta)
end

function ToolsArray(vs::AbstractArray{SpeasyVariable})
    das = DimArray.(vs)
    sharedims = dims(das[1])
    for da in das
        @assert dims(da) == sharedims
    end
    cat(das...; dims=sharedims)
end

TimeSeries(vs::AbstractArray{SpeasyVariable}) = ToolsArray(vs)

end