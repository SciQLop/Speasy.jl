module SpeasyDimensionalDataExt
using DimensionalData
using Speasy
using Speasy: AbstractSupportDataContainer
using Unitful
import Speasy: get_data, getdimarray
import DimensionalData: DimArray, DimStack, dims

is_scalar(v) = ndims(v) == 2 && size(v, 2) == 1

function DimensionalData.dims(v::SpeasyVariable)
    dim1 = Ti(v.dims[1])
    dim2 = Y(v.dims[2])
    return (dim1, dim2)
end

"""
    DimArray(v::SpeasyVariable; add_unit=false, standardize=false)

Convert a `SpeasyVariable` to a `DimArray`.
By default, it does not add units.

Set `standardize=true` to standardize the variable:
- make scalar variables 1D (https://github.com/SciQLop/speasy/issues/149)
"""
function DimArray(v::SpeasyVariable; add_unit = false, standardize = false)
    values = add_unit ? parent(v) .* Unitful.unit(v) : parent(v)
    name = v.name
    metadata = v.metadata
    return if standardize && is_scalar(v)
        DimArray(vec(values), dims(v)[1]; name, metadata)
    else
        DimArray(values, dims(v); name, metadata)
    end 
end

function DimArray(v::AbstractSupportDataContainer; unit = unit(v))
    data = parent(v)
    dims = ndims(data) == 1 ? (Ti(),) : (Ti(), Y())
    return DimArray(data * unit, dims; name = v.name, metadata = v.metadata)
end

function DimArray(vs::AbstractArray{SpeasyVariable})
    das = DimArray.(vs)
    sharedims = dims(das[1])
    for da in das
        @assert dims(da) == sharedims
    end
    return cat(das...; dims = sharedims)
end

DimStack(vs::AbstractArray{SpeasyVariable}) = DimStack(DimArray.(vs)...)

function Speasy.getdimarray(args...; add_unit = true, kwargs...)
    v = get_data(args...; kwargs...)
    return isnothing(v) ? nothing : DimArray(v; add_unit)
end
end
