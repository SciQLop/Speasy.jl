module TimeseriesToolsExt
using TimeseriesTools
using Speasy
import TimeseriesTools: ToolsArray, TimeSeries

function ToolsArray(v::SpeasyVariable)
    name = Symbol(v.name)
    dims = (Ti(v.time), Dim{name}(v.columns))
    ToolsArray(v.values, dims; name, metadata=v.meta)
end

function ToolsArray(vs::AbstractArray{SpeasyVariable})
    das = DimArray.(vs)
    sharedims = dims(das[1])
    for da in das
        @assert dims(da) == sharedims
    end
    cat(das...; dims=sharedims)
end

TimeSeries(v::SpeasyVariable) = ToolsArray(v)
TimeSeries(vs::AbstractArray{SpeasyVariable}) = ToolsArray(vs)

end