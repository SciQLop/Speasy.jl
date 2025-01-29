module DimensionalDataExt
using DimensionalData
using Speasy
import DimensionalData: DimArray, DimStack

function DimArray(v::SpeasyVariable)
    name = Symbol(v.name)
    dims = (Ti(v.time), Dim{name}(v.columns))
    DimArray(v.values, dims; name, metadata=v.meta)
end

DimStack(vs::AbstractArray{SpeasyVariable}) = DimStack(DimArray.(vs)...)

end