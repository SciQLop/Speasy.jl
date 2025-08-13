function workload()
    io = IOContext(IOBuffer(), :color => true)
    return spz_var = get_data("cda/OMNI_HRO_1MIN/flow_speed", "2016-6-2", "2016-6-2T00:10:00")
    show(io, MIME"text/plain"(), spz_var)
end
