module SpeasyDimensionalDataExt
using DimensionalData
using Speasy
using Speasy: tdimnum
import Speasy: get_data
import DimensionalData: DimArray, DimStack, dims

is_scalar(v) = ndims(v) == 2 && !isnothing(tdimnum(v)) && size(v, 3 - tdimnum(v)) == 1

function DimensionalData.dims(v::SpeasyVariable)
    t = something(tdimnum(v), ndims(v) + 1)
    return ntuple(ndims(v)) do i
        i == t && return Ti(v.dims[i])
        d = v.dims[i]
        lookup = ndims(d) == 1 ? d : 1:size(v, i)
        j = i < t ? i : i - 1
        j == 1 ? Y(lookup) : j == 2 ? Z(lookup) : Dim{Symbol(:dim, j)}(lookup)
    end
end

"""
    DimArray(v::SpeasyVariable; standardize=false)

Convert a `SpeasyVariable` to a `DimArray`.
By default, it does not add units.

Set `standardize=true` to standardize the variable:
- make scalar variables 1D (https://github.com/SciQLop/speasy/issues/149)
"""
function DimArray(v::SpeasyVariable; standardize = false)
    values = v.data
    name = v.name
    metadata = v.metadata
    return if standardize && is_scalar(v)
        DimArray(vec(values), dims(v)[tdimnum(v)]; name, metadata)
    else
        DimArray(values, dims(v); name, metadata)
    end
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

end
