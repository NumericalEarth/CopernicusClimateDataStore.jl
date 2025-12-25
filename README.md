<!-- Title -->
<h1 align="center">
  CopernicusClimateDataStore.jl
</h1>

<!-- description -->
<p align="center">
  <strong>🌍 Julia interface to the <a href="https://cds.climate.copernicus.eu/">Copernicus Climate Data Store</a> for downloading ERA5 reanalysis data</strong>
</p>

<p align="center">
  <a href="https://numericalearth.github.io/CopernicusClimateDataStore.jl/dev/">
    <img alt="Documentation" src="https://img.shields.io/badge/documentation-in%20development-orange?style=flat-square">
  </a>
</p>

CopernicusClimateDataStore.jl wraps the [`era5cli`](https://era5cli.readthedocs.io/) command-line tool,
providing a convenient Julia interface for downloading ERA5 hourly and monthly data to NetCDF or GRIB.

### Installation

```julia
using Pkg
Pkg.add(url="https://github.com/NumericalEarth/CopernicusClimateDataStore.jl")
```

### Before you start

You need a Copernicus Climate Data Store account:

1. **Create an account** at https://cds.climate.copernicus.eu/
2. **Accept the ERA5 Terms of Use** at https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels
3. **Configure your API key**:
   ```bash
   era5cli config --key YOUR_PERSONAL_ACCESS_TOKEN
   ```

Your personal access token is on your [CDS profile page](https://cds.climate.copernicus.eu/).

### Quick start

Download and visualize 2-metre temperature over Europe:

```julia
using CopernicusClimateDataStore
using NCDatasets
using CairoMakie

files = hourly(variables = "2m_temperature",
               startyear = 2020,
               months = 6,
               days = 21,
               hours = 12,
               area = (lat = (35, 70), lon = (-15, 40)),
               outputprefix = "europe")

# Load the data
ds = NCDataset(first(files))
λ = ds["longitude"][:]         # degrees East
φ = ds["latitude"][:]          # degrees North
T = ds["t2m"][:, :, 1] .- 273.15  # K → °C
close(ds)

# Plot
fig, ax, hm = heatmap(λ, φ, T; colormap = :thermal)
Colorbar(fig[1, 2], hm; label = "Temperature (°C)")
ax.xlabel = "λ (°E)"
ax.ylabel = "φ (°N)"
save("temperature.png", fig)
```

This will produce

<img width="1184" height="874" alt="image" src="https://github.com/user-attachments/assets/dcb19c81-bf8c-4183-b770-53a1f92ef6e1" />

### Key arguments

| Argument | Description |
|:---------|:------------|
| `variables` | Variable name, e.g. `"2m_temperature"`, `"total_precipitation"` |
| `startyear` | Year to download (required) |
| `months` | Month or months (1–12) |
| `days` | Day or days (1–31) |
| `hours` | Hour or hours (0–23) |
| `area` | Bounding box: `(lat = (south, north), lon = (west, east))` |
| `format` | `"netcdf"` (default) or `"grib"` |
| `outputprefix` | Prefix for output filename |
| `merge` | Merge all data into a single file (default: `false`) |

By default, one file is created per month. Use `merge = true` for a single file.

### Common variables

| Request name | NetCDF name | Description |
|:-------------|:------------|:------------|
| `2m_temperature` | `t2m` | 2-metre temperature (K) |
| `10m_u_component_of_wind` | `u10` | 10-metre zonal wind (m/s) |
| `10m_v_component_of_wind` | `v10` | 10-metre meridional wind (m/s) |
| `total_precipitation` | `tp` | Total precipitation (m) |
| `mean_sea_level_pressure` | `msl` | Mean sea level pressure (Pa) |

See the [CDS ERA5 documentation](https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels) for a complete list.
