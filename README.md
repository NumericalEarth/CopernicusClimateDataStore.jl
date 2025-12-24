# CopernicusClimateDataStore.jl

Julia wrapper around the [Copernicus Climate Data Store (CDS)](https://cds.climate.copernicus.eu/)
for downloading ERA5 reanalysis data.

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/YOUR_USERNAME/CopernicusClimateDataStore.jl")
```

## CDS Account Setup

Before downloading data, you must:

1. **Create a CDS account** at https://cds.climate.copernicus.eu/
2. **Accept the Terms of Use** for the ERA5 dataset at
   https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels?tab=download#manage-licences
3. **Configure your API key** by running:
   ```bash
   era5cli config --key YOUR_PERSONAL_ACCESS_TOKEN
   ```

Your personal access token can be found on your CDS profile page after logging in.

## Quick Start

```julia
using CopernicusClimateDataStore
using NCDatasets
using CairoMakie

# Download 2m temperature for Europe, Jan 1, 2020 at 12:00 UTC
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

# Load the downloaded file
filename = first(files)
ds = NCDataset(filename)

lon = ds["longitude"][:]
lat = ds["latitude"][:]
temp_C = ds["t2m"][:, :, 1] .- 273.15
close(ds)

# Plot
fig = Figure(size = (800, 600))
ax = Axis(fig[1, 1], xlabel = "Longitude", ylabel = "Latitude")
hm = heatmap!(ax, lon, lat, temp_C', colormap = :thermal)
Colorbar(fig[1, 2], hm, label = "Temperature (°C)")
save("temperature.png", fig)
```

## API

### `hourly(; variables, startyear, ...)`

Download ERA5 hourly data.

**Key arguments:**
- `variables`: Variable name(s), e.g. `"2m_temperature"`
- `startyear`, `endyear`: Year range
- `months`, `days`, `hours`: Time filters
- `area`: Bounding box `(lat = (south, north), lon = (west, east))`
- `format`: `"netcdf"` (default) or `"grib"`
- `outputprefix`: Prefix for output filename
- `dryrun`: If `true`, print command without downloading
- `splitmonths`: Split output by month (default: `true`)
- `merge`: Merge all output into a single file (default: `false`)

**Note:** By default, one file is created per month. Use `merge=true` for a single file.

### Common variables

| Request name | NetCDF name | Description |
|-------------|-------------|-------------|
| `2m_temperature` | `t2m` | 2 metre temperature (K) |
| `10m_u_component_of_wind` | `u10` | 10 metre U wind (m/s) |
| `10m_v_component_of_wind` | `v10` | 10 metre V wind (m/s) |
| `total_precipitation` | `tp` | Total precipitation (m) |

## Examples

See the `examples/` directory for Literate-style examples including an animation
of European temperature evolution.

## License

Apache License 2.0
