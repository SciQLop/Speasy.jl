abstract type AbstractDataSet end

@kwdef struct DataSet <: AbstractDataSet
    name::String
    parameters::Vector{String}
    provider::Symbol = :cda
end

parameters(ds::DataSet) = ds.parameters
provider(ds::DataSet) = ds.provider

function products(ds::DataSet; provider=provider(ds))
    name = ds.name
    map(parameters(ds)) do p
        "$provider/$name/$p"
    end
end

function get_data(ds::AbstractDataSet, args...)
    map(products(ds)) do p
        replace_fillval_by_nan!(get_data(p, args...))
    end
end