# Quick Start

This guide shows how to download ERA5 data, load it, and create a simple plot.

## Download ERA5 data

```julia
using CopernicusClimateDataStore

# Download 2m temperature for a single snapshot
hourly(
    variables = "2m_temperature",
    startyear = 2020,
    months = 1,
    days = 1,
    hours = 12,
    area = (lat = (35, 60), lon = (-10, 25)),
    format = "netcdf",
    outputprefix = "europe"
)
```

This downloads a NetCDF file with a name like `europe_2m_temperature_2020-01_hourly_10W-25E_35N-60N.nc`.

## Load and plot

```julia
using NCDatasets
using CairoMakie

# Find the downloaded file
filename = first(filter(f -> startswith(f, "europe") && endswith(f, ".nc"), readdir()))

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

## Key arguments

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

## Common variables

| Request name | NetCDF name | Description |
|-------------|-------------|-------------|
| `2m_temperature` | `t2m` | 2 metre temperature (K) |
| `10m_u_component_of_wind` | `u10` | 10 metre U wind (m/s) |
| `10m_v_component_of_wind` | `v10` | 10 metre V wind (m/s) |
| `total_precipitation` | `tp` | Total precipitation (m) |
| `mean_sea_level_pressure` | `msl` | Mean sea level pressure (Pa) |

