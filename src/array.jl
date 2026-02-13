
function Base.view(A::AbstractSupportDataContainer, raw_inds...)
    inds = to_indices(A, raw_inds)
    data = view(parent(A), inds...)
    inds isa Tuple{Vararg{Integer}} && return data # scalar output
    return @set A.data = data
end

function keys_view(keys, inds)
    return map(enumerate(keys)) do (i, key)
        N = ndims(key)
        view(key, inds[i:i-1+N]...)
    end
end

function Base.view(A::SpeasyVariable, raw_inds...)
    inds = to_indices(A, raw_inds)
    data = view(parent(A), inds...)
    inds isa Tuple{Vararg{Integer}} && return data # scalar output
    raw_keys = keys_view(A.dims, inds)
    new_keys = ntuple(ndims(data)) do d
        raw_keys === nothing && return axes(data, d)
        raw_keys[d]
    end
    return @set (@set A.data = data).dims = new_keys
end