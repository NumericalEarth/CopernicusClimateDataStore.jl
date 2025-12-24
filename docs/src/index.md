# CopernicusClimateDataStore.jl

Julia wrapper around the [Copernicus Climate Data Store (CDS)](https://cds.climate.copernicus.eu/)
for downloading ERA5 reanalysis data.

This package wraps the [`era5cli`](https://era5cli.readthedocs.io/) Python command-line tool,
providing a convenient Julia interface for downloading ERA5 and ERA5-Land data.

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/YOUR_USERNAME/CopernicusClimateDataStore.jl")
```

## CDS Account Setup

Before downloading data, you must:

1. **Create a CDS account** at <https://cds.climate.copernicus.eu/>
2. **Accept the Terms of Use** for the ERA5 dataset at
   <https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels?tab=download#manage-licences>
3. **Configure your API key** by running:
   ```bash
   era5cli config --key YOUR_PERSONAL_ACCESS_TOKEN
   ```

Your personal access token can be found on your CDS profile page after logging in.

## Quick Start

### Download ERA5 data

```julia
using CopernicusClimateDataStore

# Download 2m temperature for a single snapshot
files = hourly(
    variables = "2m_temperature",
    startyear = 2020,
    months = 1,
    days = 1,
    hours = 12,
    area = (lat = (35, 60), lon = (-10, 25)),
    format = "netcdf",
    outputprefix = "europe"
)

# files contains the path(s) to the downloaded NetCDF file(s)
filename = first(files)
```

### Load and plot

```julia
using NCDatasets
using CairoMakie

# Open the NetCDF file
ds = NCDataset(filename)

lon = ds["longitude"][:]
lat = ds["latitude"][:]
temp_K = ds["t2m"][:, :, 1]
temp_C = temp_K .- 273.15

close(ds)

# Plot
fig = Figure(size = (800, 600))
ax = Axis(fig[1, 1], xlabel = "Longitude", ylabel = "Latitude")
hm = heatmap!(ax, lon, lat, temp_C', colormap = :thermal)
Colorbar(fig[1, 2], hm, label = "Temperature (°C)")
fig
```

## Key Arguments

| Argument | Description |
|----------|-------------|
| `variables` | Variable name(s), e.g. `"2m_temperature"` |
| `startyear` | Year to download |
| `months` | Month(s), 1–12 |
| `days` | Day(s), 1–31 |
| `hours` | Hour(s), 0–23 |
| `area` | Bounding box: `(lat = (south, north), lon = (west, east))` |
| `format` | `"netcdf"` or `"grib"` |
| `outputprefix` | Prefix for output filename |
| `dryrun` | If `true`, print command without downloading |
| `splitmonths` | Split output by month (default: `true`) |
| `merge` | Merge all output into a single file (default: `false`) |

**Note:** By default, `era5cli` creates one file per month. If you request multiple months,
you will receive multiple files. Use `merge=true` to combine all data into a single file.

## Common Variables

| Request name | NetCDF name | Description |
|-------------|-------------|-------------|
| `2m_temperature` | `t2m` | 2 metre temperature (K) |
| `10m_u_component_of_wind` | `u10` | 10 metre U wind (m/s) |
| `10m_v_component_of_wind` | `v10` | 10 metre V wind (m/s) |
| `total_precipitation` | `tp` | Total precipitation (m) |
| `mean_sea_level_pressure` | `msl` | Mean sea level pressure (Pa) |
