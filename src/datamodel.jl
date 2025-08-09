function SpeasyProduct(id, metadata=Dict(); provider=:cda, kwargs...)
    if !contain_provider(id)
        @info "Provider not found in $id, using $provider"
        id = "$provider/$id"
    end
    Product(id, get_data, id, metadata; kwargs...)
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