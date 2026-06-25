module CopernicusClimateDataStore

# Pure Julia implementation using HTTP.jl + JSON3.jl
# No Python dependency required!

export retrieve, read_cds_credentials, CDSCredentials
export install_era5cli, era5cli_cmd  # Legacy Python-based functions (deprecated)

include("cds_client.jl")

# Legacy Python-based functions (kept for backwards compatibility, but deprecated)
# Users should migrate to the pure Julia retrieve() function

using CondaPkg

"""
    install_era5cli()

**DEPRECATED:** Use pure Julia `retrieve()` function instead.

Install the `era5cli` command-line tool (version ≥ 2.0.1) using CondaPkg.
Returns the path to the installed CLI executable.
"""
function install_era5cli()
    @warn "install_era5cli() is deprecated. Use pure Julia retrieve() function instead."
    @info "Installing era5cli via CondaPkg..."
    CondaPkg.add_pip("era5cli"; version=">=2.0.1")
    cli = era5cli_cmd()
    @info "era5cli installed at: $cli"
    return cli
end

"""
    era5cli_cmd()

**DEPRECATED:** Use pure Julia `retrieve()` function instead.

Return the absolute path to the `era5cli` executable.
"""
function era5cli_cmd()
    @warn "era5cli_cmd() is deprecated. Use pure Julia retrieve() function instead."
    cli = CondaPkg.which("era5cli")
    if isnothing(cli)
        @warn "era5cli not found. Attempting to install..."
        CondaPkg.add_pip("era5cli"; version=">=2.0.1")
        cli = CondaPkg.which("era5cli")
        if isnothing(cli)
            error("Failed to locate era5cli after installation.")
        end
    end
    return cli
end

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
