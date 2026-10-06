
function Base.view(A::AbstractSupportDataContainer, raw_inds...)
    inds = to_indices(A, raw_inds)
    data = view(parent(A), inds...)
    inds isa Tuple{Vararg{Integer}} && return data # scalar output
    return @set A.data = data
end

# A time-varying axis spans its own dimension and the time dimension, in the variable's order.
function axis_view(A, inds, i)
    key = A.dims[i]
    ndims(key) == 1 && return view(key, inds[i])
    ndims(key) == 2 || throw(ArgumentError("cannot slice the $(ndims(key))-dimensional axis of dimension $i"))
    t = tdimnum(A)
    return view(key, (i < t ? (inds[i], inds[t]) : (inds[t], inds[i]))...)
end

function Base.view(A::SpeasyVariable, raw_inds...)
    inds = to_indices(A, raw_inds)
    data = view(parent(A), inds...)
    inds isa Tuple{Vararg{Integer}} && return data # scalar output
    kept = filter(i -> !(inds[i] isa Integer), Tuple(eachindex(inds)))
    # Linear, logical or multidimensional indices map no axis to a dimension.
    dims = length(inds) == ndims(A) && length(kept) == ndims(data) ? map(i -> axis_view(A, inds, i), kept) : axes(data)
    return @set (@set A.data = data).dims = dims
end

# Base's generic `getindex` goes through `similar`, which would keep the unsliced axes.
Base.getindex(A::SpeasyVariable, I::Union{Real, AbstractArray, Colon, CartesianIndex}...) = _copy(view(A, I...))
Base.@propagate_inbounds Base.getindex(A::SpeasyVariable, I::Vararg{Int}) = parent(A)[I...]
_copy(v::SpeasyVariable) = @set v.data = copy(parent(v))
_copy(x) = x[] # 0-dimensional view of a scalar
