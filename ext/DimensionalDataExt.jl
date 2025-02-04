module DimensionalDataExt
using DimensionalData
using Speasy
using Speasy: AbstractSupportDataContainer
using Unitful
import DimensionalData: DimArray, DimStack

"""
    DimArray(v::SpeasyVariable; unit=unit(v), add_axes=true)

Convert a `SpeasyVariable` to a `DimArray`.
By default, it adds axes and adds units. Disabling `add_axes` could improve performance.
"""
function DimArray(v::SpeasyVariable; unit=unit(v), add_axes=true)
    v = replace_fillval_by_nan(v)
    axes = v.axes
    name = Symbol(v.name)
    dims = (Ti(v.time), Dim{name}(v.columns))
    metadata = v.meta
    add_axes && metadata["axes"] = axes
    DimArray(v.values * unit, dims; name, metadata)
end

function DimArray(v::AbstractSupportDataContainer; unit=unit(v))
    name = Symbol(v.name)
    data = v.values
    dims = ndims(data) == 1 ? (Ti(),) : (Ti(), Dim{name}())
    DimArray(data * unit, dims; name)
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