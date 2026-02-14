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
    using Speasy.SpaceDataModel: tdimnum
    spz_var = get_data("amda/imf", tmin, tmax)
    @test spz_var isa SpeasyVariable
    @test spz_var.dims isa Tuple
    @test occursin("Units: ns", string(spz_var.dims[1]))
    @test meta(spz_var.dims[1])["FIELDNAM"] == "Time"
    @test eltype(times(spz_var)) <: AbstractDateTime
    @test tdimnum(spz_var) == 1
    @test tdimnum(get_data("amda/imf", tmin, tmax; transpose = true)) == 2
    @test units(spz_var) == "nT"
    @test unit(spz_var) == u"nT"

    # Transpose
    spz_var_t = get_data("amda/imf", tmin, tmax; transpose = true)
    @test meta(spz_var_t.dims[2])["FIELDNAM"] == "Time"
    @test eltype(times(spz_var_t)) <: AbstractDateTime
    @test spz_var_t' == spz_var

    @test get_data(NamedTuple, ["amda/imf", "amda/dst"], tmin, tmax) isa NamedTuple{(:imf, :dst)}
    names = (:amda_imf, :amda_dst)
    @test get_data(NamedTuple, ["amda/imf", "amda/dst"], tmin, tmax; names) isa NamedTuple{names}
end

@testitem "N-Dimensional data" begin
    tint_r = ["2015-10-30T05:14:44", "2015-10-30T05:17:44"]
    vdf_e_spz = get_data("cda/MMS1_FPI_BRST_L2_DES-DIST/mms1_des_dist_brst", tint_r...)
    @test vdf_e_spz isa SpeasyVariable
end

@testitem "Array and SpaceDataModel Interface" setup = [DataShare] begin
    using SpaceDataModel: times
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

    # Test similar method for VariableAxis
    spz_var = get_data("cda/SOHO_ERNE-HED_L2-1MIN/AH", "20211028T06", "20211028T06:10")
    axis = spz_var.dims[1]
    @test axis isa Speasy.VariableAxis
    similar_axis = similar(axis, Float64, (10,))
    @test similar_axis isa Speasy.VariableAxis
    @test eltype(similar_axis) == Float64
    @test size(similar_axis) == (10,)

    @test times(spz_var) == spz_var.dims[1]
    @test isnothing(times(spz_var.dims[2]))

    @testset "view" begin
        view_var = selectdim(spz_var, 2, [1, 3, 5])
        @test size(view_var) == (10, 3)
        @test size(view_var.dims[2]) == (3,)
    end
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
            mms1_products.DIS.MMS1_FPI_FAST_L2_DIS_MOMS.mms1_dis_energyspectr_omni_fast,
        ],
        "2017-01-01T02:00:00",
        "2017-01-01T02:00:05"
    )
    @test data isa Vector{<:SpeasyVariable}
    @test data[3].dims[1] isa Speasy.VariableAxis


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

@testitem "TimeSeriesExt.jl" setup = [DataShare] begin
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
    cda_omni_params = list_parameters(:cda, "OMNI_HRO_1MIN"; verbose = true)
    @test cda_omni_params isa Vector{String}
    @test length(cda_omni_params) > 0
end

@testitem "find_datasets" begin
    # Test listing all datasets for a provider
    amda_datasets = find_datasets(:amda)
    @test amda_datasets isa AbstractVector{String}
    @test length(amda_datasets) > 0

    # Test listing datasets with filter
    cda_datasets = find_datasets(:cda)
    @test cda_datasets isa AbstractVector{String}
    @test length(cda_datasets) > 0

    # Test filtering by substring
    omni_datasets = find_datasets(:cda, :OMNI)
    @test omni_datasets isa AbstractVector{String}
    @test all(ds -> occursin("OMNI", ds), omni_datasets)
    @test length(omni_datasets) <= length(cda_datasets)

    # Test filtering with multiple substrings
    specific_datasets = find_datasets(:cda, :OMNI, :HRO)
    @test specific_datasets isa AbstractVector{String}
    @test all(ds -> occursin("OMNI", ds) && occursin("HRO", ds), specific_datasets)
    @test length(specific_datasets) <= length(omni_datasets)
end

@testitem "issue 223" begin
    # https://github.com/SciQLop/speasy/issues/223
    data = get_data(NamedTuple, ["cda/STA_L1_HET/Proton_Flux", "cda/OMNI_HRO_1MIN/flow_speed"], "20201028", "20201029")
    @test data isa NamedTuple
    @test haskey(data, :flow_speed)
    @test haskey(data, :Proton_Flux)
end

@testitem "OverlayDict" begin
    using Speasy.PythonCall
    using Speasy: OverlayDict

    # Create a base PyDict
    base = pydict(Dict("a" => 1, "b" => 2))
    d = OverlayDict{String, Int}(base)

    # Test reading from base
    @test d["a"] == 1
    # Test writing to overlay
    d["c"] = 3
    @test d["c"] == 3

    # Test overriding base value
    d["a"] = 10
    @test d["a"] == 10
    @test pyconvert(Int, base["a"]) == 1  # base unchanged

    # Test haskey
    @test haskey(d, "a")
    @test !haskey(d, "d")

    # Test get with default
    @test get(d, "a", 0) == 10
    @test get(d, "d", 0) == 0

    # Test keys and length
    @test length(d) == 3

    # Test iteration
    collected = collect(d)
    @test length(collected) == 3
    @test ("a" => 10) in collected
    @test ("c" => 3) in collected
end
