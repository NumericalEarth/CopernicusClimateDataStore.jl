# CopernicusClimateDataStore.jl

Julia wrapper around the [Copernicus Climate Data Store (CDS)](https://cds.climate.copernicus.eu/) for downloading ERA5 reanalysis data.

This package wraps the [`era5cli`](https://era5cli.readthedocs.io/) Python command-line tool, providing a convenient Julia interface for downloading ERA5 and ERA5-Land data.

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/YOUR_USERNAME/CopernicusClimateDataStore.jl")
```

## CDS Account Setup (Required)

Before downloading any data, you must:

### 1. Create a CDS Account

Register at https://cds.climate.copernicus.eu/

### 2. Accept Terms of Use

Navigate to the [ERA5 hourly dataset page](https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels) and scroll down to accept the Terms of Use. **This step is mandatory** — downloads will fail without it.

### 3. Configure API Credentials

Follow the instructions at https://cds.climate.copernicus.eu/how-to-api to set up your credentials.

Create a file `~/.cdsapirc` with:

```
url: https://cds.climate.copernicus.eu/api
key: <YOUR-PERSONAL-ACCESS-TOKEN>
```

You can find your personal access token on your CDS user profile page after logging in.

## Quick Start

```julia
using CopernicusClimateDataStore

# Download 2m temperature for a single day
hourly(
    variables = "2m_temperature",
    startyear = 2020,
    months = 1,
    days = 1,
    hours = 12,
    format = "netcdf"
)

# Download multiple variables with spatial subsetting
hourly(
    variables = ["2m_temperature", "total_precipitation"],
    startyear = 2020,
    months = [6, 7, 8],  # summer months
    area = (lat = (35, 60), lon = (-10, 30)),  # Europe
    format = "netcdf",
    outputprefix = "europe_summer"
)

# Dry run (print command without downloading)
hourly(
    variables = "2m_temperature",
    startyear = 2020,
    dryrun = true
)
```

## API Reference

### `hourly(; kwargs...)`

Download ERA5 hourly data.

**Required Arguments:**
- `variables`: Variable name(s) to download (string or vector of strings)
- `startyear`: First year to download

**Optional Arguments:**
| Argument | Default | Description |
|----------|---------|-------------|
| `endyear` | `startyear` | Last year to download |
| `months` | all | Month(s) to download (1-12) |
| `days` | all | Day(s) to download (1-31) |
| `hours` | all | Hour(s) to download (0-23) |
| `area` | global | Bounding box `(lat=(south,north), lon=(west,east))` |
| `format` | `"netcdf"` | Output format: `"netcdf"` or `"grib"` |
| `outputprefix` | `"era5"` | Prefix for output filenames |
| `overwrite` | `true` | Overwrite existing files without prompting |
| `threads` | `1` | Number of parallel download threads |
| `splitmonths` | `true` | Create separate files per month |
| `merge` | `false` | Merge all output into single file |
| `dryrun` | `false` | Print command without downloading |
| `land` | `false` | Use ERA5-Land dataset |
| `ensemble` | `false` | Download ensemble data |
| `levels` | `nothing` | Pressure level(s) for 3D variables |

### `info(; what=:variables, land=false, levels=false)`

Display available ERA5 variables or pressure levels.

### `install_era5cli()`

Manually install the `era5cli` Python tool (normally done automatically).

### `era5cli_cmd()`

Get the path to the `era5cli` executable.

## Area Specification

The `area` argument accepts several formats:

```julia
# NamedTuple with lat/lon ranges (most intuitive)
area = (lat = (40, 60), lon = (-10, 20))

# Tuple in era5cli order (lat_max, lon_min, lat_min, lon_max)
area = (60, -10, 40, 20)

# Vector in era5cli order
area = [60, -10, 40, 20]
```

## Available Variables

Common single-level variables include:
- `2m_temperature` - 2 metre temperature
- `10m_u_component_of_wind` - 10 metre U wind component
- `10m_v_component_of_wind` - 10 metre V wind component
- `mean_sea_level_pressure` - Mean sea level pressure
- `total_precipitation` - Total precipitation
- `surface_pressure` - Surface pressure
- `sea_surface_temperature` - Sea surface temperature

Run `info()` to see all available variables.

## Example: Historical Climate Event

Download data for the date the Kyoto Protocol entered into force (February 16, 2005):

```julia
using CopernicusClimateDataStore

hourly(
    variables = "2m_temperature",
    startyear = 2005,
    months = 2,
    days = 16,
    hours = 12,
    format = "netcdf",
    outputprefix = "kyoto_protocol"
)
```

## Troubleshooting

### "Request failed" or authentication errors

1. Verify your `~/.cdsapirc` file exists and contains valid credentials
2. Make sure you've accepted the Terms of Use on the dataset page
3. Check that your API key is current (keys can expire)

### Old CDS API errors

The old Climate Data Store was shut down on September 3, 2024. This package uses `era5cli >= 2.0.1` which is compatible with the new CDS. If you see errors about API versions, try:

```julia
using CopernicusClimateDataStore
install_era5cli()  # Force reinstall
```

### NetCDF formatting differences

NetCDF files from the new CDS may have different formatting than older files. Some variable names or attributes may differ. See the [era5cli issue tracker](https://github.com/eWaterCycle/era5cli/issues) for known issues.

## Integration with ClimaOcean

This package is designed to work with [ClimaOcean.jl](https://github.com/CliMA/ClimaOcean.jl). A ClimaOcean extension (similar to `ClimaOceanCopernicusMarineExt.jl`) can be added to enable seamless ERA5 data downloads within the ClimaOcean `DataWrangling` framework.

## License

Apache License 2.0
