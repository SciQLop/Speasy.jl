using Speasy
using Test
using TestItems, TestItemRunner

@run_package_tests filter = ti -> !(:skipci in ti.tags)

@testitem "Speasy.jl" begin
    using Dates
    using Dates: AbstractDateTime
    using Unitful
    spz_var = get_data("amda/imf", "2016-6-2", "2016-6-5")
    @test spz_var isa SpeasyVariable
    @test spz_var.dims isa Tuple
    @test times(spz_var) isa Vector{<:AbstractDateTime}
    @test units(spz_var) == "nT"
    @test unit(spz_var) == u"nT"
end

@testitem "Array Interface" begin
    spz_var = get_data("amda/imf", "2016-6-2", "2016-6-5")
    @info typeof(spz_var)
    @test spz_var isa AbstractArray
    @test Array(spz_var) isa Array
    @test size(spz_var, 2) == 3
    @test spz_var[1, 2] == Array(spz_var)[1, 2]
    @test eltype(spz_var) == Float32
    @test similar(spz_var) isa Array{Float32,2}
end

@testitem "Dynamic inventory" begin
    spz = speasy
    # Dynamic inventory
    amda_tree = spz.inventories.data_tree.amda
    @test get_data(amda_tree.Parameters.ACE.MFI.ace_imf_all.imf, "2016-6-2", "2016-6-5") isa SpeasyVariable

    mms1_products = spz.inventories.tree.cda.MMS.MMS1
    @test get_data(
        [
            mms1_products.FGM.MMS1_FGM_SRVY_L2.mms1_fgm_b_gsm_srvy_l2,
            mms1_products.DIS.MMS1_FPI_FAST_L2_DIS_MOMS.mms1_dis_tempperp_fast,
            mms1_products.DIS.MMS1_FPI_FAST_L2_DIS_MOMS.mms1_dis_temppara_fast
        ],
        "2017-01-01T02:00:00",
        "2017-01-01T02:00:15"
    ) isa Vector{<:SpeasyVariable}


    # More complex requests
    products = [
        spz.inventories.tree.amda.Parameters.Wind.SWE.wnd_swe_kp.wnd_swe_vth,
        spz.inventories.tree.amda.Parameters.Wind.SWE.wnd_swe_kp.wnd_swe_pdyn,
        spz.inventories.tree.amda.Parameters.Wind.SWE.wnd_swe_kp.wnd_swe_n,
        spz.inventories.tree.cda.Wind.WIND.MFI.WI_H2_MFI.BGSE,
        spz.inventories.tree.ssc.Trajectories.wind,
    ]
    intervals = [["2010-01-02", "2010-01-02T10"], ["2009-08-02", "2009-08-02T10"]]
    data = get_data(products, intervals)
    @test data isa Vector{Vector}
    @test data[1] isa Vector{<:SpeasyVariable}
end

@testitem "DimensionalData" begin
    using DimensionalData
    spz_var1 = get_data("amda/imf", "2016-6-2", "2016-6-5")
    @test DimArray(spz_var1) isa DimArray

    spz_var2 = get_data("amda/solo_het_omni_hflux", "2020-11-28T00:00", "2020-11-28T00:10")
    @test DimArray(spz_var2) isa DimArray
end

@testitem "TimeSeriesExt.jl" tags = [:skipci] begin
    using TimeSeries
    spz_var = get_data("amda/imf", "2016-6-2", "2016-6-5")
    @test TimeArray(spz_var) isa TimeArray
end

@testitem "MakieExt.jl" tags = [:skipci] begin
    import Pkg
    Pkg.add("CairoMakie")
    using CairoMakie
    da = get_data("amda/imf", "2016-6-2", "2016-6-5")
    plot(da)
end