using Test
using CopernicusClimateDataStore

@testset "CopernicusClimateDataStore.jl" begin

    @testset "CDSCredentials struct" begin
        # Test basic construction
        creds = CDSCredentials("https://cds.climate.copernicus.eu/api", "test-key-123")
        @test creds.url == "https://cds.climate.copernicus.eu/api"
        @test creds.key == "test-key-123"
    end

    @testset "Credential reading" begin
        # Test with environment variables
        withenv("CDSAPI_URL" => "https://test.url", "CDSAPI_KEY" => "test-key") do
            creds = read_cds_credentials()
            @test creds.url == "https://test.url"
            @test creds.key == "test-key"
        end
    end

    @testset "Pure Julia API exports" begin
        # Test that main functions are exported
        @test isdefined(CopernicusClimateDataStore, :retrieve)
        @test isdefined(CopernicusClimateDataStore, :read_cds_credentials)
        @test isdefined(CopernicusClimateDataStore, :CDSCredentials)
        @test isdefined(CopernicusClimateDataStore, :submit_cds_request)
        @test isdefined(CopernicusClimateDataStore, :poll_request_status)
        @test isdefined(CopernicusClimateDataStore, :download_cds_file)
    end

end

#####
##### Manual download test (requires network + CDS credentials)
#####

"""
    test_era5_download()

Download ERA5 2m temperature for a small region and single timestep.

This test requires:
1. Network access
2. A valid CDS account with accepted Terms of Use
3. Properly configured ~/.cdsapirc with your API credentials:
   ```
   url: https://cds.climate.copernicus.eu/api
   key: <your-api-key>
   ```

Run manually with:
```julia
include("test/runtests.jl")
test_era5_download()
```
"""
function test_era5_download(output_path = tempname() * ".nc")
    @info """
    Downloading small ERA5 test dataset.

    Dataset: reanalysis-era5-single-levels
    Variable: 2m_temperature
    Time: 2020-01-01 00:00
    Area: 1°×1° (51N-50N, 0E-1E)
    """

    params = Dict(
        "product_type" => "reanalysis",
        "variable" => ["2m_temperature"],
        "year" => ["2020"],
        "month" => ["01"],
        "day" => ["01"],
        "time" => ["00:00"],
        "data_format" => "netcdf",
        "area" => [51, 0, 50, 1]  # [North, West, South, East]
    )

    result = retrieve("reanalysis-era5-single-levels", params, output_path)

    @info "Download complete!" file=result size=filesize(result)

    return result
end
