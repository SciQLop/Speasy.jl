function SpeasyProduct(id, metadata=Dict(); provider=:cda, kwargs...)
    if !contain_provider(id)
        @info "Provider not found in $id, using $provider"
        id = "$provider/$id"
    end
    Product(id, getdimarray, id, metadata; kwargs...)
end