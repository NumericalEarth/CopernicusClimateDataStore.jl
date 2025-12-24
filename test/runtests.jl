using Test
using CopernicusClimateDataStore

@testset "CopernicusClimateDataStore.jl" begin

    @testset "Area formatting" begin
        # Test nothing passthrough
        @test CopernicusClimateDataStore.format_area(nothing) === nothing

        # Test tuple passthrough (already in era5cli order)
        area_tuple = (60.0, -10.0, 40.0, 20.0)  # lat_max, lon_min, lat_min, lon_max
        @test CopernicusClimateDataStore.format_area(area_tuple) == area_tuple

        # Test vector conversion
        area_vec = [60.0, -10.0, 40.0, 20.0]
        @test CopernicusClimateDataStore.format_area(area_vec) == (60.0, -10.0, 40.0, 20.0)

        # Test NamedTuple conversion (lat, lon) order
        area_nt = (lat=(40.0, 60.0), lon=(-10.0, 20.0))
        formatted = CopernicusClimateDataStore.format_area(area_nt)
        @test formatted == (60.0, -10.0, 40.0, 20.0)  # lat_max, lon_min, lat_min, lon_max

        # Test NamedTuple conversion (lon, lat) order
        area_nt_rev = (lon=(-10.0, 20.0), lat=(40.0, 60.0))
        formatted_rev = CopernicusClimateDataStore.format_area(area_nt_rev)
        @test formatted_rev == (60.0, -10.0, 40.0, 20.0)
    end

    @testset "Command construction" begin
        # Use a mock CLI path for testing command construction without installing era5cli
        mock_cli = "/usr/bin/era5cli"

        # Basic command with single variable
        cmd = CopernicusClimateDataStore.build_hourly_cmd(
            variables = "2m_temperature",
            startyear = 2020,
            cli = mock_cli
        )
        cmd_str = string(cmd)
        @test occursin("hourly", cmd_str)
        @test occursin("--variables", cmd_str)
        @test occursin("2m_temperature", cmd_str)
        @test occursin("--startyear", cmd_str)
        @test occursin("2020", cmd_str)
        @test occursin("--overwrite", cmd_str)  # default is true
        @test occursin("--format", cmd_str)
        @test occursin("netcdf", cmd_str)

        # Command with multiple variables
        cmd_multi = CopernicusClimateDataStore.build_hourly_cmd(
            variables = ["2m_temperature", "total_precipitation"],
            startyear = 2020,
            cli = mock_cli
        )
        cmd_multi_str = string(cmd_multi)
        @test occursin("2m_temperature", cmd_multi_str)
        @test occursin("total_precipitation", cmd_multi_str)

        # Command with year range
        cmd_range = CopernicusClimateDataStore.build_hourly_cmd(
            variables = "2m_temperature",
            startyear = 2018,
            endyear = 2020,
            cli = mock_cli
        )
        cmd_range_str = string(cmd_range)
        @test occursin("--startyear", cmd_range_str)
        @test occursin("2018", cmd_range_str)
        @test occursin("--endyear", cmd_range_str)
        @test occursin("2020", cmd_range_str)

        # Command with time filters
        cmd_time = CopernicusClimateDataStore.build_hourly_cmd(
            variables = "2m_temperature",
            startyear = 2020,
            months = [1, 2],
            days = 15,
            hours = [0, 12],
            cli = mock_cli
        )
        cmd_time_str = string(cmd_time)
        @test occursin("--months", cmd_time_str)
        @test occursin("--days", cmd_time_str)
        @test occursin("--hours", cmd_time_str)

        # Command with area
        cmd_area = CopernicusClimateDataStore.build_hourly_cmd(
            variables = "2m_temperature",
            startyear = 2020,
            area = (lat=(40.0, 60.0), lon=(-10.0, 20.0)),
            cli = mock_cli
        )
        cmd_area_str = string(cmd_area)
        @test occursin("--area", cmd_area_str)
        @test occursin("60.0", cmd_area_str)  # lat_max
        @test occursin("-10.0", cmd_area_str) # lon_min
        @test occursin("40.0", cmd_area_str)  # lat_min
        @test occursin("20.0", cmd_area_str)  # lon_max

        # Command with overwrite=false should NOT have --overwrite
        cmd_no_overwrite = CopernicusClimateDataStore.build_hourly_cmd(
            variables = "2m_temperature",
            startyear = 2020,
            overwrite = false,
            cli = mock_cli
        )
        cmd_no_overwrite_str = string(cmd_no_overwrite)
        @test !occursin("--overwrite", cmd_no_overwrite_str)

        # Command with dryrun
        cmd_dryrun = CopernicusClimateDataStore.build_hourly_cmd(
            variables = "2m_temperature",
            startyear = 2020,
            dryrun = true,
            cli = mock_cli
        )
        cmd_dryrun_str = string(cmd_dryrun)
        @test occursin("--dryrun", cmd_dryrun_str)

        # Command with land dataset
        cmd_land = CopernicusClimateDataStore.build_hourly_cmd(
            variables = "2m_temperature",
            startyear = 2020,
            land = true,
            cli = mock_cli
        )
        cmd_land_str = string(cmd_land)
        @test occursin("--land", cmd_land_str)

        # Command with GRIB format
        cmd_grib = CopernicusClimateDataStore.build_hourly_cmd(
            variables = "2m_temperature",
            startyear = 2020,
            format = "grib",
            cli = mock_cli
        )
        cmd_grib_str = string(cmd_grib)
        @test occursin("grib", cmd_grib_str)

        # Command with merge
        cmd_merge = CopernicusClimateDataStore.build_hourly_cmd(
            variables = "2m_temperature",
            startyear = 2020,
            merge = true,
            cli = mock_cli
        )
        cmd_merge_str = string(cmd_merge)
        @test occursin("--merge", cmd_merge_str)

        # Command with pressure levels
        cmd_levels = CopernicusClimateDataStore.build_hourly_cmd(
            variables = "geopotential",
            startyear = 2020,
            levels = [850, 500],
            cli = mock_cli
        )
        cmd_levels_str = string(cmd_levels)
        @test occursin("--levels", cmd_levels_str)
        @test occursin("850", cmd_levels_str)
        @test occursin("500", cmd_levels_str)
    end

    @testset "Kyoto Protocol date command" begin
        # Use a mock CLI path for testing
        mock_cli = "/usr/bin/era5cli"

        # The Kyoto Protocol entered into force on February 16, 2005
        # This test validates the command construction for that specific date
        cmd = CopernicusClimateDataStore.build_hourly_cmd(
            variables = "2m_temperature",
            startyear = 2005,
            months = 2,
            days = 16,
            hours = 12,  # noon UTC
            format = "netcdf",
            outputprefix = "kyoto_protocol_era5",
            cli = mock_cli
        )
        cmd_str = string(cmd)

        @test occursin("hourly", cmd_str)
        @test occursin("2m_temperature", cmd_str)
        @test occursin("2005", cmd_str)
        @test occursin("--months", cmd_str)
        @test occursin("--days", cmd_str)
        @test occursin("16", cmd_str)
        @test occursin("--hours", cmd_str)
        @test occursin("12", cmd_str)
        @test occursin("kyoto_protocol_era5", cmd_str)
    end

end

#####
##### Manual download test (requires network + CDS credentials)
#####

"""
    test_kyoto_protocol_download()

Download ERA5 2m temperature for the date the Kyoto Protocol entered into force
(February 16, 2005, 12:00 UTC).

This test requires:
1. Network access
2. A valid CDS account with accepted Terms of Use
3. Properly configured ~/.cdsapirc

Run manually with:
```julia
include("test/runtests.jl")
test_kyoto_protocol_download()
```
"""
function test_kyoto_protocol_download(; dryrun=false)
    @info """
    Downloading ERA5 2m temperature snapshot for Kyoto Protocol ratification date.
    
    Date: February 16, 2005, 12:00 UTC
    Variable: 2m_temperature (surface air temperature)
    
    This is the date the Kyoto Protocol entered into force, after Russia's
    ratification brought the treaty to the required 55% of global emissions.
    """

    # Download a small global snapshot
    hourly(
        variables = "2m_temperature",
        startyear = 2005,
        months = 2,
        days = 16,
        hours = 12,
        format = "netcdf",
        outputprefix = "kyoto_protocol_era5",
        overwrite = true,
        dryrun = dryrun
    )

    if !dryrun
        @info "Download complete! Check for kyoto_protocol_era5*.nc file."
    end
end

