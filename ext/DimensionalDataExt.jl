module DimensionalDataExt
using DimensionalData
using Speasy
using Speasy: axes
using Unitful
import DimensionalData: DimArray, DimStack

function DimArray(v::SpeasyVariable; unit=unit(v))
    v = replace_fillval_by_nan(v)
    axes = v.axes
    name = Symbol(v.name)
    dims = (Ti(v.time), Dim{name}(v.columns))
    metadata = v.meta
    metadata["axes"] = axes
    DimArray(v.values * unit, dims; name, metadata)
end

function DimArray(vs::AbstractArray{SpeasyVariable})
    das = DimArray.(vs)
    sharedims = dims(das[1])
    for da in das
        @assert dims(da) == sharedims
    end
    cat(das...; dims=sharedims)
end

DimStack(vs::AbstractArray{SpeasyVariable}) = DimStack(DimArray.(vs)...)

end