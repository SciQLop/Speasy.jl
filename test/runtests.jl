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
    using SpaceDataModel: name
    product = spz"cda/OMNI_HRO_1MIN/flow_speed"
    @test name(product) == "cda/OMNI_HRO_1MIN/flow_speed"
    @test name(spz"OMNI_HRO_1MIN/flow_speed") == "cda/OMNI_HRO_1MIN/flow_speed"
    @test eval(Meta.parse(repr(product))) == product

    # Test multiple parameters with spaces
    products_spaces = spz"cda/OMNI_HRO_1MIN/flow_speed, Bx_gse , By_gse"
    @test products_spaces isa Tuple
    @test length(products_spaces) == 3
    @test name(products_spaces[1]) == "cda/OMNI_HRO_1MIN/flow_speed"
    @test name(products_spaces[2]) == "cda/OMNI_HRO_1MIN/Bx_gse"
    @test name(products_spaces[3]) == "cda/OMNI_HRO_1MIN/By_gse"

    # Test error case - invalid format
    @test_throws Exception eval(:(spz"invalid_format,param"))
end

@testitem "Speasy.jl" setup = [DataShare] begin
    using Dates: AbstractDateTime
    using Unitful
    using Speasy.SpaceDataModel: getdata, getmeta, tdimnum
    spz_var = get_data("amda/imf", tmin, tmax)
    @test spz_var isa SpeasyVariable
    @test spz_var.dims isa Tuple
    @test occursin("Units: ns", string(spz_var.dims[2]))
    @testset "Metadata access" begin
        m = spz_var.metadata
        @test haskey(m, "CATDESC")
        @test @allocations(haskey(m, "CATDESC")) <= 3
        @test m["CATDESC"] == "imf"
        @test getmeta(spz_var.dims[2])["FIELDNAM"] == "Time"
    end
    @test eltype(times(spz_var)) <: AbstractDateTime
    @test tdimnum(spz_var) == 2
    @test units(spz_var) == "nT"
    @test unit(spz_var) == u"nT"

    spz_var_py = get_data("amda/imf", tmin, tmax; layout = :python)
    @test tdimnum(spz_var_py) == 1
    @test getmeta(spz_var_py.dims[1])["FIELDNAM"] == "Time"
    @test spz_var_py' == spz_var
    @test_throws ArgumentError get_data("amda/imf", tmin, tmax; layout = :numpy)

    @test get_data(NamedTuple, ["amda/imf", "amda/dst"], tmin, tmax) isa NamedTuple{(:imf, :dst)}
    @test getdata(spz"amda/imf", tmin, tmax) isa SpeasyVariable
    names = (:amda_imf, :amda_dst)
    @test get_data(NamedTuple, ["amda/imf", "amda/dst"], tmin, tmax; names) isa NamedTuple{names}
end

@testitem "get_data masks per component" setup = [DataShare] begin
    using SpaceDataModel: mask_invalid, ValidityChecks
    for layout in (:julia, :python)
        v = get_data("amda/imf", tmin, tmax; sanitize = false, layout)
        v["VALIDMAX"] = [1.0e9, 0.0, 1.0e9]
        expected = mask_invalid(Array(v), ValidityChecks(v), layout === :julia ? 1 : 2)
        @test any(isnan, expected)
        @test isequal(Array(mask_invalid(v)), expected)
        @test isequal(Array(Speasy._sanitize(v)), expected)
    end
    raw = get_data("cda/OMNI_HRO_1MIN/IMF", "2016-1-1", "2016-1-10"; sanitize = false)  # Int32, FILLVAL 99
    imf = Speasy._sanitize(raw)
    @test eltype(imf) == Float64
    @test isequal(Array(imf), mask_invalid(Array(raw), ValidityChecks(raw)))
    @test any(isnan, imf)
end

@testitem "N-Dimensional data" begin
    using SpaceDataModel: mask_invalid, ValidityChecks, name, times
    using Speasy.SpaceDataModel: tdimnum
    # numpy (time, phi = DEPEND_1, theta = DEPEND_2, energy = DEPEND_3); phi and energy are time-varying
    tint = ("2015-10-30T05:14:44", "2015-10-30T05:17:44")
    v = get_data("cda/MMS1_FPI_BRST_L2_DES-DIST/mms1_des_dist_brst", tint...; sanitize = false)
    p = SpeasyVariable(v.py; layout = :python) # shares v's memory
    nt = size(p, 1)
    @test size(v) == (32, 16, 32, nt)
    @test tdimnum(v) == 4
    @test isequal(v, PermutedDimsArray(p, (2, 3, 4, 1)))
    @test name.(v.dims) == (v["DEPEND_1"], v["DEPEND_2"], v["DEPEND_3"], "time")
    @test v.dims[1] == p.dims[2]'
    @test Array(v) == collect(parent(v)) && Array(p) == collect(parent(p))
    @test size.(view(v, 2:3, :, 4:4, 5:7).dims) == ((2, 3), (16,), (1, 3), (3,))
    w = v[2, :, 4, 5:7]
    @test size.(w.dims) == ((16,), (3,)) && times(w) == times(v)[5:7]
    @test w == Array(v)[2, :, 4, 5:7]
    snapshot = view(v, :, :, :, 5)
    @test isnothing(tdimnum(snapshot))
    @test snapshot.dims[1] == v.dims[1][:, 5]

    # Bounds per phi; energy has as many channels, so masking along the wrong dimension differs
    v["VALIDMAX"] = p["VALIDMAX"] = [i <= 16 ? 1.0e-25 : 1.0e9 for i in 1:32]
    expected = mask_invalid(Array(v), ValidityChecks(v), 1)
    @test any(isnan, expected) && !all(isnan, expected)
    @test isequal(parent(mask_invalid(v)), expected)
    @test isequal(parent(mask_invalid(p)), PermutedDimsArray(expected, (4, 1, 2, 3)))
    @test isequal(parent(Speasy._sanitize(v)), expected)
end

@testitem "Array and SpaceDataModel Interface" setup = [DataShare] begin
    using SpaceDataModel: times
    using Speasy.PythonCall: PyArray
    spz_var = get_data("amda/imf", tmin, tmax)
    @test spz_var isa AbstractArray
    @test parent(spz_var) isa PyArray
    @test_nowarn Array(spz_var)
    @test size(spz_var, 1) == 3
    @test spz_var[1, 2] == Array(spz_var)[1, 2]
    @test eltype(spz_var) == Float32

    copied_var = copy(spz_var)
    @test copied_var isa SpeasyVariable
    @test !isa(parent(copied_var), PyArray)

    # Test similar method for VariableAxis
    spz_var = get_data("cda/SOHO_ERNE-HED_L2-1MIN/AH", "20211028T06", "20211028T06:10")
    axis = spz_var.dims[2]
    @test axis isa Speasy.VariableAxis
    similar_axis = similar(axis, Float64, (10,))
    @test similar_axis isa Speasy.VariableAxis
    @test eltype(similar_axis) == Float64
    @test size(similar_axis) == (10,)

    @test times(spz_var) == spz_var.dims[2]
    @test isnothing(times(spz_var.dims[1]))

    @testset "view" begin
        view_var = selectdim(spz_var, 1, [1, 3, 5])
        @test size(view_var) == (3, 10)
        @test size(view_var.dims[1]) == (3,)
        @test times(selectdim(spz_var, 1, 2)) == times(spz_var)
        w = spz_var[2, 3:5]
        @test times(w) == times(spz_var)[3:5]
        @test w == Array(spz_var)[2, 3:5]
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
    da = DimArray(spz_var1)
    @test dims(da, Ti) == dims(da)[2]
    @test parent(da) === parent(spz_var1)
    @test dims(DimArray(get_data("amda/imf", tmin, tmax; layout = :python)))[1] isa Ti

    spz_var2 = get_data("amda/solo_het_omni_hflux", "2020-11-28T00:00", "2020-11-28T00:10")
    @test DimArray(spz_var2) isa DimArray
end

@testitem "TimeSeriesExt.jl" setup = [DataShare] begin
    using TimeSeries
    spz_var = get_data("amda/imf", tmin, tmax)
    ta = TimeArray(spz_var)
    @test values(ta) == permutedims(spz_var)
end

@testitem "MakieExt.jl" tags = [:skipci] setup = [DataShare] begin
    import Pkg
    Pkg.add("CairoMakie")
    using CairoMakie
    da = get_data("amda/imf", tmin, tmax)
    plot(da)
end

@testitem "Provider registry" begin
    @test "OMNI_HRO_1MIN" in keys(Speasy.cda)
    @test_throws KeyError Speasy.cda["omni_hro_1min"]
    omni, ace = Speasy.cda["OMNI_HRO_1MIN"], Speasy.amda["ace-imf-all"]
    @test "flow_speed" in keys(omni) && "imf" in keys(ace)
    # CDA parameter uids carry the dataset; AMDA ones stand alone.
    @test Speasy._product_id(omni, "flow_speed") == "cda/OMNI_HRO_1MIN/flow_speed"
    @test Speasy._product_id(ace, "imf") == "amda/imf"
    @test getmeta(omni)["start_date"] isa String
    t0, t1 = "2016-6-2", "2016-6-2T01"
    @test getdata(ace, t0, t1)["imf"].data == getdata(ace["imf"], t0, t1).data
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
