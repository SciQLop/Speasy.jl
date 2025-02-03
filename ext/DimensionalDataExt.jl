module DimensionalDataExt
using DimensionalData
using Speasy
using Unitful
import DimensionalData: DimArray, DimStack

function DimArray(v::SpeasyVariable; unit=unit(v))
    v = replace_fillval_by_nan(v)
    name = Symbol(v.name)
    dims = (Ti(v.time), Dim{name}(v.columns))
    DimArray(v.values * unit, dims; name, metadata=v.meta)
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