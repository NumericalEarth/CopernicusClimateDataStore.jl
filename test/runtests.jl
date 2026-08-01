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

    @testset "request_with_retries" begin
        # Succeeds once the transient failures stop
        calls = Ref(0)
        result = CopernicusClimateDataStore.request_with_retries(; initial_delay=0.01) do
            calls[] += 1
            calls[] < 3 ? error("transient") : :ok
        end
        @test result == :ok
        @test calls[] == 3

        # Rethrows after exhausting attempts
        calls[] = 0
        @test_throws ErrorException CopernicusClimateDataStore.request_with_retries(; attempts=2, initial_delay=0.01) do
            calls[] += 1
            error("persistent")
        end
        @test calls[] == 2
    end

    @testset "hourly file naming and skip-existing (offline)" begin
        # A single variable keeps the historical names; existing files short-circuit
        # the request entirely, so these run without credentials or network.
        mktempdir() do dir
            single = joinpath(dir, "era5.nc")
            touch(single)
            paths = hourly(variables="2m_temperature", startyear=2020,
                           months=1, days=1, hours=0, directory=dir)
            @test paths == [single]

            dated = joinpath(dir, "era5_2020_1_1.nc")
            touch(dated)
            paths = hourly(variables="2m_temperature", startyear=2020,
                           months=1, days=1, hours=[0, 12], directory=dir)
            @test paths == [dated]
        end

        # Multiple variables get per-variable files, returned in input order
        mktempdir() do dir
            t2m = joinpath(dir, "era5_2m_temperature.nc")
            u10 = joinpath(dir, "era5_10m_u_component_of_wind.nc")
            touch(t2m)
            touch(u10)
            paths = hourly(variables=["2m_temperature", "10m_u_component_of_wind"],
                           startyear=2020, months=1, days=1, hours=0, directory=dir)
            @test paths == [t2m, u10]
        end
    end

    @testset "resolve_dataset (offline)" begin
        @test CopernicusClimateDataStore.resolve_dataset(:era5, nothing) ==
              ("reanalysis-era5-single-levels", "reanalysis")
        @test CopernicusClimateDataStore.resolve_dataset(:era5, [1000, 850]) ==
              ("reanalysis-era5-pressure-levels", "reanalysis")
        @test CopernicusClimateDataStore.resolve_dataset(:era5_land, nothing) ==
              ("reanalysis-era5-land", nothing)
        @test_throws ArgumentError CopernicusClimateDataStore.resolve_dataset(:era5_land, [1000])
        @test_throws ArgumentError CopernicusClimateDataStore.resolve_dataset(:bogus, nothing)
    end

    @testset "zip-wrapped CDS response unwrapping (offline)" begin
        # reanalysis-era5-land wraps its netcdf output in a zip archive even when
        # format=netcdf is requested; download_cds_file must transparently unwrap it.
        mktempdir() do dir
            payload_path = joinpath(dir, "data_0.nc")
            write(payload_path, "fake netcdf bytes")

            zip_path = joinpath(dir, "response.nc")
            run(Cmd(`zip -j -q $zip_path $payload_path`))
            @test CopernicusClimateDataStore.is_zip_file(zip_path)

            CopernicusClimateDataStore.unwrap_zip_response!(zip_path)
            @test !CopernicusClimateDataStore.is_zip_file(zip_path)
            @test read(zip_path, String) == "fake netcdf bytes"
        end

        # A plain (non-zip) file is left untouched
        mktempdir() do dir
            plain_path = joinpath(dir, "plain.nc")
            write(plain_path, "not a zip")
            @test !CopernicusClimateDataStore.is_zip_file(plain_path)
            CopernicusClimateDataStore.unwrap_zip_response!(plain_path)
            @test read(plain_path, String) == "not a zip"
        end
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
