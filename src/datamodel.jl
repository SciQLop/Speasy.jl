"""
    SpeasyProduct(id; provider=:cda, metadata=NoMetadata(), kw...)

The Speasy parameter `id` (`"provider/dataset/parameter"`, or a standalone one like `"amda/imf"`),
prefixed with `provider` when `id` names none; `kw` merge into `metadata`.
"""
struct SpeasyProduct{MD} <: DataSource
    id::String
    metadata::MD
end

function SpeasyProduct(id; provider=:cda, metadata=NoMetadata(), kwargs...)
    if !contain_provider(id)
        @info "Provider not found in $id, using $provider"
        id = "$provider/$id"
    end
    return SpeasyProduct(String(id), merge(metadata, kwargs))
end

name(p::SpeasyProduct) = getmeta(p, "name", p.id)
SpaceDataModel.getdata(p::SpeasyProduct, t0, t1; kw...) = get_data(p.id, t0, t1; kw...)

Base.show(io::IO, p::SpeasyProduct) = print(io, "spz", repr(p.id))
function Base.show(io::IO, ::MIME"text/plain", p::SpeasyProduct)
    printstyled(io, "SpeasyProduct: "; bold=true)
    printstyled(io, p.id; color=:yellow)
    for (k, v) in pairs(p.metadata)
        print(io, "\n  ", k, ": ", v)
    end
end

"""
    spz"provider/dataset/parameter"
    spz"provider/dataset/parameter1,parameter2"

String macro to create a SpeasyProduct from a string identifier.
Supports multiple parameters separated by commas, which returns a tuple of SpeasyProduct objects.

# Examples
```julia
# Single parameter
product = spz"cda/OMNI_HRO_1MIN/flow_speed"

# Multiple parameters
products = spz"cda/OMNI_HRO_1MIN/flow_speed,Pressure"
```
"""
macro spz_str(s)
    if contains(s, ",")
        # Multiple parameters case
        parts = split(s, "/")
        if length(parts) < 3
            error("Invalid format. Expected 'provider/dataset/parameter1,parameter2'")
        end
        provider_dataset = join(parts[1:end-1], "/")
        parameters = strip.(split(parts[end], ","))
        # Create tuple expression
        product_exprs = (:(SpeasyProduct($("$provider_dataset/$param"))) for param in parameters)
        ex = Expr(:tuple, product_exprs...)
        return ex
    else
        # Single parameter case
        return :(SpeasyProduct($s))
    end
end