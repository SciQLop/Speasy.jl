using Speasy
using Test

@testitem "Speasy.jl" begin
    using Dates
    const spz = speasy
    spz_var = get_data("amda/imf", "2016-6-2", "2016-6-5")
    @test spz_var isa SpeasyVariable
    @test spz_var.time isa Vector{DateTime}

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
    ) isa Vector{SpeasyVariable}


    # More complex requests
    products = [
        spz.inventories.tree.amda.Parameters.Wind.SWE.wnd_swe_kp.wnd_swe_vth,
        spz.inventories.tree.amda.Parameters.Wind.SWE.wnd_swe_kp.wnd_swe_pdyn,
        spz.inventories.tree.amda.Parameters.Wind.SWE.wnd_swe_kp.wnd_swe_n,
        spz.inventories.tree.cda.Wind.WIND.MFI.WI_H2_MFI.BGSE,
        spz.inventories.tree.ssc.Trajectories.wind,
    ]
    intervals = [["2010-01-02", "2010-01-02T10"], ["2009-08-02", "2009-08-02T10"]]
    @test get_data(products, intervals) isa Vector{Vector{SpeasyVariable}}
end

@testitem "TimeSeriesExt.jl" begin
    using TimeSeries
    spz_var = get_data("amda/imf", "2016-6-2", "2016-6-5")
    @test TimeArray(spz_var) isa TimeArray
end

@testitem "MakieExt.jl" begin
    using CairoMakie
    da = get_data("amda/imf", "2016-6-2", "2016-6-5")
    plot(da)
end