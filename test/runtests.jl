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

    @testset "ERA5 Download Integration Test" begin
        # Only run if CDS credentials are available
        has_credentials = try
            read_cds_credentials()
            true
        catch
            false
        end

        if has_credentials
            @info "CDS credentials found - running download test"

            # Test ERA5 download (Kyoto Protocol ratification date)
            output_path = joinpath(tempdir(), "kyoto_test.nc")

            params = Dict(
                "product_type" => ["reanalysis"],
                "variable"     => ["2m_temperature"],
                "year"         => ["2005"],
                "month"        => ["02"],
                "day"          => ["16"],
                "time"         => ["12:00"],
                "area"         => [45, -10, 35, 0],
                "data_format"  => "netcdf",
            )

            result = retrieve("reanalysis-era5-single-levels", params, output_path)

            @test isfile(result)
            @test filesize(result) > 0
            @info "Successfully downloaded ERA5 test data" path=result size=filesize(result)

            # Cleanup
            rm(result; force=true)
        else
            @info "Skipping download test - no CDS credentials available"
            @test_skip true
        end
    end

end
