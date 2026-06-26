# CopernicusClimateDataStore.jl

Pure Julia client for the [Copernicus Climate Data Store (CDS)](https://cds.climate.copernicus.eu/)
for downloading ERA5 reanalysis data. No Python dependency required.

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/NumericalEarth/CopernicusClimateDataStore.jl")
```

## CDS Account Setup

Before downloading data, you must:

1. **Create a CDS account** at <https://cds.climate.copernicus.eu/>
2. **Accept the Terms of Use** for the ERA5 dataset at
   <https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels?tab=download#manage-licences>
3. **Create `~/.cdsapirc`** with your API credentials:
   ```
   url: https://cds.climate.copernicus.eu/api
   key: YOUR_PERSONAL_ACCESS_TOKEN
   ```

Your personal access token can be found on your CDS profile page after logging in.

## Quick Start

### Download ERA5 data

```julia
using CopernicusClimateDataStore

params = Dict(
    "product_type" => ["reanalysis"],
    "variable"     => ["2m_temperature"],
    "year"         => ["2020"],
    "month"        => ["01"],
    "day"          => ["01"],
    "time"         => ["12:00"],
    "area"         => [60, -10, 35, 25],   # [North, West, South, East]
    "data_format"  => "netcdf",
)

retrieve("reanalysis-era5-single-levels", params, "europe.nc")
```

### Load and plot

```julia
using NCDatasets
using CairoMakie

ds = NCDataset("europe.nc")

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

## Common Variables

| Request name | NetCDF name | Description |
|-------------|-------------|-------------|
| `2m_temperature` | `t2m` | 2 metre temperature (K) |
| `10m_u_component_of_wind` | `u10` | 10 metre U wind (m/s) |
| `10m_v_component_of_wind` | `v10` | 10 metre V wind (m/s) |
| `total_precipitation` | `tp` | Total precipitation (m) |
| `mean_sea_level_pressure` | `msl` | Mean sea level pressure (Pa) |
