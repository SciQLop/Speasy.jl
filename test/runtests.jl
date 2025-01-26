using Speasy
using Test

using TimeSeries

@testset "Speasy.jl" begin
    spz_var = get_data("amda/imf", "2016-6-2", "2016-6-5")
end

@testset "TimeSeriesExt.jl" begin
    spz_var = get_data("amda/imf", "2016-6-2", "2016-6-5")
    ta = TimeArray(spz_var)
end