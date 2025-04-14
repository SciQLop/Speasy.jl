dataset_id(ds::DataSet) = ds.name
parameters(ds) = ds.data
provider(ds::DataSet) = :cda

function products(ds; provider=provider(ds))
    uid = dataset_id(ds)
    map(Base.values(parameters(ds))) do p
        "$provider/$uid/$p"
    end
end