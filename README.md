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

CopernicusClimateDataStore.jl is a Julia client for the [Copernicus Climate Data Store API v2](https://cds.climate.copernicus.eu/).

### Installation

```julia
using Pkg
Pkg.add("CopernicusClimateDataStore")
```

### Before you start

You need a Copernicus Climate Data Store account:

1. **Create an account** at https://cds.climate.copernicus.eu/
2. **Accept the ERA5 Terms of Use** at https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels
3. **Create `~/.cdsapirc`** with your API credentials:
   ```
   url: https://cds.climate.copernicus.eu/api
   key: YOUR_PERSONAL_ACCESS_TOKEN
   ```

Your personal access token is on your [CDS profile page](https://cds.climate.copernicus.eu/).

### Quick start

Download and visualize 2-metre temperature over Europe:

```julia
using CopernicusClimateDataStore
using NCDatasets
using CairoMakie

params = Dict(
    "product_type" => ["reanalysis"],
    "variable"     => ["2m_temperature"],
    "year"         => ["2020"],
    "month"        => ["06"],
    "day"          => ["21"],
    "time"         => ["12:00"],
    "area"         => [70, -15, 35, 40],   # [North, West, South, East]
    "data_format"  => "netcdf",
)

retrieve("reanalysis-era5-single-levels", params, "europe.nc")

# Load the data
ds = NCDataset("europe.nc")
λ = ds["longitude"][:]
φ = ds["latitude"][:]
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

### Common variables

| Request name | NetCDF name | Description |
|:-------------|:------------|:------------|
| `2m_temperature` | `t2m` | 2-metre temperature (K) |
| `10m_u_component_of_wind` | `u10` | 10-metre zonal wind (m/s) |
| `10m_v_component_of_wind` | `v10` | 10-metre meridional wind (m/s) |
| `total_precipitation` | `tp` | Total precipitation (m) |
| `mean_sea_level_pressure` | `msl` | Mean sea level pressure (Pa) |

See the [CDS ERA5 documentation](https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels) for a complete list.

### Convenience functions

For common workflows, use the `hourly()` and `yearly()` functions instead of building parameter dictionaries manually:

#### Download hourly data

```julia
using CopernicusClimateDataStore

# Download specific hours
hourly(;
    variables = "2m_temperature",
    startyear = 2020,
    months = 6,
    days = 21,
    hours = [0, 6, 12, 18],
    area = [70, -15, 35, 40],  # [North, West, South, East]
    directory = "data/ERA5"
)
```

#### Download yearly data (recommended for long simulations)

For multi-year simulations, download full years at once (8760-8784 hours per file) instead of individual hourly files:

```julia
# Download 10 years of temperature data in 10 files
yearly(;
    variables = "2m_temperature",
    years = 2000:2010,
    area = [70, -15, 35, 40],  # Optional: omit for global
    directory = "data/ERA5_yearly"
)
```

**Benefits of yearly files:**
- **8784× fewer API calls** (one request per year instead of per hour)
- **Reusable across simulations** (download once, use many times)
- **Simpler file management** (one file per variable per year)

**Note:** Download time and file size depend on region size (smaller regions are faster/smaller). CDS queue load also affects download time.
