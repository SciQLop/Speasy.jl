module SpeasyDimensionalDataExt
using DimensionalData
using Speasy
using Speasy: AbstractSupportDataContainer
using Unitful
import Speasy: get_data
import DimensionalData: DimArray, DimStack

"""
    DimArray(v::SpeasyVariable; unit=unit(v), add_axes=true)

Convert a `SpeasyVariable` to a `DimArray`.
By default, it adds axes and adds units. Disabling `add_axes` could improve performance.
"""
function DimArray(v::SpeasyVariable; f=sanitize, unit=unit(v), add_axes=true, add_metadata=false, use_dimname=false)
    values = f(v)
    axes = v.axes
    name = Symbol(v.name)
    ydim = use_dimname ? Dim{name}(v.columns) : Y(1:length(v.columns))
    dims = (Ti(v.time), ydim)
    metadata = Dict{Any,Any}(v.meta)
    if isspectrogram(v)
        y = axes[2]
        ymeta = y.meta
        add_metadata && (metadata[:ymeta] = ymeta)
        haskey(ymeta, "SCALETYP") && (metadata[:yscale] = ymeta["SCALETYP"])
        haskey(ymeta, "LABLAXIS") && (metadata[:ylabel] = ymeta["LABLAXIS"])
        haskey(ymeta, "UNITS") && (metadata[:yunit] = ymeta["UNITS"])
    end
    add_axes && push!(metadata, "axes" => axes)
    DimArray(values * unit, dims; name, metadata)
end

function DimArray(v::AbstractSupportDataContainer; unit=unit(v))
    name = Symbol(v.name)
    data = v.values
    dims = ndims(data) == 1 ? (Ti(),) : (Ti(), Dim{name}())
    metadata = v.meta
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

end