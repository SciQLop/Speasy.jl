module SpeasyDimensionalDataExt
using DimensionalData
using Speasy
using Speasy: AbstractSupportDataContainer
using Unitful
import Speasy: get_data, getdimarray
import DimensionalData: DimArray, DimStack, dims
using SpaceDataModel: NoMetadata


function DimensionalData.dims(v::SpeasyVariable)
    dim1 = Ti(v.dims[1])
    dim2 = Y(1:length(v.dims[2]))
    return (dim1, dim2)
end

"""
    DimArray(v::SpeasyVariable; add_unit=true, add_axes=true, add_metadata=true)

Convert a `SpeasyVariable` to a `DimArray`.
By default, it adds axes and adds units. Disabling `add_axes` could improve performance.
"""
function DimArray(v::SpeasyVariable; add_unit=true, add_axes=true, add_metadata=true)
    values = add_unit ? parent(v) .* Unitful.unit(v) : parent(v)
    name = Symbol(v.name)

    metadata = add_metadata ? meta(v) : NoMetadata()
    DimArray(values, dims(v); name, metadata)
end

function DimArray(v::AbstractSupportDataContainer; unit=unit(v))
    name = Symbol(v.name)
    data = v.values
    dims = ndims(data) == 1 ? (Ti(),) : (Ti(), Dim{name}())
    metadata = meta(v)
    DimArray(data * unit, dims; name, metadata)
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

function Speasy.getdimarray(args...; add_unit=true, add_axes=true, add_metadata=true, kwargs...)
    v = get_data(args...; kwargs...)
    isnothing(v) ? nothing : DimArray(v; add_unit, add_axes, add_metadata)
end
end