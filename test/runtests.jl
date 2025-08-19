using Speasy
using Test
using TestItems, TestItemRunner

@run_package_tests filter = ti -> !(:skipci in ti.tags)

@testitem "Aqua" begin
    using Aqua
    Aqua.test_all(Speasy)
end

@testsnippet DataShare begin
    tmin = "2016-6-2"
    tmax = "2016-6-2T02"
end

@testitem "spz_str macro" begin
    # Test single parameter
    using Speasy: Product
    product = spz"cda/OMNI_HRO_1MIN/flow_speed"
    @test product isa Product
    @test product.data == "cda/OMNI_HRO_1MIN/flow_speed"
    @test spz"OMNI_HRO_1MIN/flow_speed" isa Product

    # Test multiple parameters with spaces
    products_spaces = spz"cda/OMNI_HRO_1MIN/flow_speed, Bx_gse , By_gse"
    @test products_spaces isa Tuple
    @test length(products_spaces) == 3
    @test products_spaces[1].data == "cda/OMNI_HRO_1MIN/flow_speed"
    @test products_spaces[2].data == "cda/OMNI_HRO_1MIN/Bx_gse"
    @test products_spaces[3].data == "cda/OMNI_HRO_1MIN/By_gse"

    # Test error case - invalid format
    @test_throws Exception eval(:(spz"invalid_format,param"))
end

@testitem "Speasy.jl" setup = [DataShare] begin
    using Dates: AbstractDateTime
    using Unitful
    spz_var = get_data("amda/imf", tmin, tmax)
    @test spz_var isa SpeasyVariable
    @test spz_var.dims isa Tuple
    @test times(spz_var) isa Vector{<:AbstractDateTime}
    @test units(spz_var) == "nT"
    @test unit(spz_var) == u"nT"
    @test get_data(NamedTuple, ["amda/imf", "amda/dst"], tmin, tmax) isa NamedTuple
end

@testitem "Array Interface" setup = [DataShare] begin
    using Speasy.PythonCall: PyArray
    spz_var = get_data("amda/imf", tmin, tmax)
    @info typeof(spz_var)
    @test spz_var isa AbstractArray
    @test parent(spz_var) isa PyArray
    @test_nowarn Array(spz_var)
    @test size(spz_var, 2) == 3
    @test spz_var[1, 2] == Array(spz_var)[1, 2]
    @test eltype(spz_var) == Float32

    copied_var = copy(spz_var)
    @test copied_var isa SpeasyVariable
    @test !isa(parent(copied_var), PyArray)
end

@testitem "Dynamic inventory" setup = [DataShare] begin
    spz = speasy
    # Dynamic inventory
    amda_tree = spz.inventories.data_tree.amda
    @test get_data(amda_tree.Parameters.ACE.MFI.ace_imf_all.imf, tmin, tmax) isa SpeasyVariable

    mms1_products = spz.inventories.tree.cda.MMS.MMS1
    data = get_data(
        [
            mms1_products.FGM.MMS1_FGM_SRVY_L2.mms1_fgm_b_gsm_srvy_l2,
            mms1_products.DIS.MMS1_FPI_FAST_L2_DIS_MOMS.mms1_dis_tempperp_fast,
            mms1_products.DIS.MMS1_FPI_FAST_L2_DIS_MOMS.mms1_dis_energyspectr_omni_fast
        ],
        "2017-01-01T02:00:00",
        "2017-01-01T02:00:05"
    ) 
    @test data isa Vector{<:SpeasyVariable}
    @test data[3]["DEPEND_1"] isa Speasy.VariableAxis


    # More complex requests
    products = [
        spz.inventories.tree.amda.Parameters.Wind.SWE.wnd_swe_kp.wnd_swe_vth,
        spz.inventories.tree.amda.Parameters.Wind.SWE.wnd_swe_kp.wnd_swe_pdyn,
        spz.inventories.tree.amda.Parameters.Wind.SWE.wnd_swe_kp.wnd_swe_n,
        spz.inventories.tree.cda.Wind.WIND.MFI.WI_H2_MFI.BGSE,
        spz.inventories.tree.ssc.Trajectories.wind,
    ]
    intervals = [["2010-01-02", "2010-01-02T01"], ["2009-08-02", "2009-08-02T01"]]
    data = get_data(products, intervals)
    @test data isa Vector{Vector}
    @test data[1] isa Vector{<:SpeasyVariable}
end

@testitem "ssc.get_data and get_data(\"ssc/...\")" begin
    @test Speasy.ssc_get_data("mms1", "2018-01-01", "2018-01-02", "gsm") isa SpeasyVariable
    @test get_data("ssc/mms1", "2018-01-01", "2018-01-02") isa SpeasyVariable
    @test get_data("ssc/mms1/gsm", "2018-01-01", "2018-01-02") isa SpeasyVariable
end

@testitem "DimensionalData" setup = [DataShare] begin
    using DimensionalData
    spz_var1 = get_data("amda/imf", tmin, tmax)
    @test DimArray(spz_var1) isa DimArray

    spz_var2 = get_data("amda/solo_het_omni_hflux", "2020-11-28T00:00", "2020-11-28T00:10")
    @test DimArray(spz_var2) isa DimArray
end

@testitem "TimeSeriesExt.jl" tags = [:skipci] setup = [DataShare] begin
    using TimeSeries
    spz_var = get_data("amda/imf", tmin, tmax)
    @test TimeArray(spz_var) isa TimeArray
end

@testitem "MakieExt.jl" tags = [:skipci] setup = [DataShare] begin
    import Pkg
    Pkg.add("CairoMakie")
    using CairoMakie
    da = get_data("amda/imf", tmin, tmax)
    plot(da)
end

@testitem "list_parameters" begin
    # Test listing parameters for a provider
    amda_params = list_parameters(:amda)
    @test amda_params isa AbstractVector{String}
    @test length(amda_params) > 0
    @test "imf" in amda_params

    # Test listing parameters for a specific dataset
    cda_omni_params = list_parameters(:cda, "OMNI_HRO_1MIN")
    @test cda_omni_params isa Vector{String}
    @test length(cda_omni_params) > 0
end

@testitem "list_datasets" begin
    # Test listing all datasets for a provider
    amda_datasets = list_datasets(:amda)
    @test amda_datasets isa AbstractVector{String}
    @test length(amda_datasets) > 0

    # Test listing datasets with filter
    cda_datasets = list_datasets(:cda)
    @test cda_datasets isa AbstractVector{String}
    @test length(cda_datasets) > 0
    
    # Test filtering by substring
    omni_datasets = list_datasets(:cda, :OMNI)
    @test omni_datasets isa AbstractVector{String}
    @test all(ds -> occursin("OMNI", ds), omni_datasets)
    @test length(omni_datasets) <= length(cda_datasets)

    # Test filtering with multiple substrings
    specific_datasets = list_datasets(:cda, :OMNI, :HRO)
    @test specific_datasets isa AbstractVector{String}
    @test all(ds -> occursin("OMNI", ds) && occursin("HRO", ds), specific_datasets)
    @test length(specific_datasets) <= length(omni_datasets)
end
