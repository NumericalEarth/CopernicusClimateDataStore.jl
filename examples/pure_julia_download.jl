# Example: Download ERA5 data using pure Julia (no Python!)

using CopernicusClimateDataStore
using Dates

# Setup: Create ~/.cdsapirc with your API credentials:
# url: https://cds.climate.copernicus.eu/api
# key: <your-api-key>

# Download ERA5 2m temperature for one day
params = Dict(
    "product_type" => "reanalysis",
    "variable" => ["2m_temperature"],
    "year" => ["2020"],
    "month" => ["01"],
    "day" => ["01"],
    "time" => ["00:00", "06:00", "12:00", "18:00"],
    "format" => "netcdf",
    "area" => [60, -10, 50, 2]  # [North, West, South, East]
)

output_file = "era5_temperature_20200101.nc"

println("Downloading ERA5 data...")
retrieve("reanalysis-era5-single-levels", params, output_file)

println("✓ Download complete: $output_file")
println("File size: $(filesize(output_file) ÷ 1024) KB")
