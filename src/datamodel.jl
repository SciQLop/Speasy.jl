function SpeasyProduct(id, metadata=Dict(); provider=:cda, kwargs...)
    id = contain_provider(id) ? id : "$provider/$id"
    Product(id, getdimarray, id, metadata; kwargs...)
end