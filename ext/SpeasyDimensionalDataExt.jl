module SpeasyDimensionalDataExt
using DimensionalData
using Speasy
using Speasy: AbstractSupportDataContainer
using Unitful
import Speasy: get_data, getdimarray, sanitize!
import DimensionalData: DimArray, DimStack, dims


DimensionalData.dims(v::SpeasyVariable) = (Ti(v.dims[1]), Y(v.dims[2]))

"""
    DimArray(v::SpeasyVariable; add_unit=true, add_axes=true, add_metadata=false)

Convert a `SpeasyVariable` to a `DimArray`.
By default, it adds axes and adds units. Disabling `add_axes` could improve performance.
"""
function DimArray(v::SpeasyVariable; f=sanitize!, add_unit=true, add_axes=true, add_metadata=true)
    values = add_unit ? parent(f(v)) * Unitful.unit(v) : parent(f(v))
    name = Symbol(v.name)

    metadata = add_metadata ? Dict{Any,Any}(meta(v)) : Dict{Any,Any}()
    if isspectrogram(v)
        y = VariableAxis(v.axes[1])
        ymeta = meta(y)
        add_metadata && (metadata[:ymeta] = ymeta)
        haskey(ymeta, "SCALETYP") && (metadata[:yscale] = ymeta["SCALETYP"])
        haskey(ymeta, "LABLAXIS") && (metadata[:ylabel] = ymeta["LABLAXIS"])
        haskey(ymeta, "UNITS") && (metadata[:yunit] = ymeta["UNITS"])
        add_axes && push!(metadata, "y" => y)
    end
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
    return DimArray(v; add_unit, add_axes, add_metadata)
end
end