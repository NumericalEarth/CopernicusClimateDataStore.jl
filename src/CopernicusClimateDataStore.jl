module CopernicusClimateDataStore

# Pure Julia implementation using HTTP.jl + JSON3.jl
# No Python dependency required!

export retrieve, read_cds_credentials, CDSCredentials
export submit_cds_request, poll_request_status, download_cds_file

include("cds_client.jl")

# Helper functions for data categorization (from original package)
"""
    hourly()

Return a tuple of hourly frequency indicator for ERA5 downloads.
"""
hourly() = ("hourly",)

"""
    monthly()

Return a tuple of monthly frequency indicator for ERA5 downloads.
"""
monthly() = ("monthly",)

"""
    info()

Display information about CopernicusClimateDataStore.jl.

**Pure Julia Implementation:**
This package now uses HTTP.jl and JSON3.jl to access the Copernicus Climate Data Store,
eliminating the Python dependency.

**Setup:**
1. Register at: https://cds.climate.copernicus.eu/
2. Accept Terms of Use for datasets you want to download
3. Create ~/.cdsapirc with your API credentials:
   ```
   url: https://cds.climate.copernicus.eu/api
   key: <your-api-key>
   ```

**Usage:**
```julia
using CopernicusClimateDataStore

params = Dict(
    "product_type" => "reanalysis",
    "variable" => ["2m_temperature"],
    "year" => ["2020"],
    "month" => ["01"],
    "day" => ["01"],
    "time" => ["00:00", "12:00"],
    "format" => "netcdf"
)

retrieve("reanalysis-era5-single-levels", params, "output.nc")
```

**Migration from Python era5cli:**
- Old: `era5cli_cmd()` + shell commands
- New: `retrieve(dataset, params, output_path)`

See documentation: https://cds.climate.copernicus.eu/api-how-to
"""
function info()
    println("""
    CopernicusClimateDataStore.jl - Pure Julia CDS API Client

    Access Copernicus Climate Data Store without Python dependency.

    Setup:
      1. Register at https://cds.climate.copernicus.eu/
      2. Create ~/.cdsapirc with your API key

    Usage:
      retrieve(dataset, params, output_path)

    See ?retrieve for details.
    """)
end

end # module CopernicusClimateDataStore
