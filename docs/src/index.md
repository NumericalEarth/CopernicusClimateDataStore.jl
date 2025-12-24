# CopernicusClimateDataStore.jl

Julia wrapper around the [Copernicus Climate Data Store (CDS)](https://cds.climate.copernicus.eu/)
for downloading ERA5 reanalysis data.

This package wraps the [`era5cli`](https://era5cli.readthedocs.io/) Python command-line tool,
providing a convenient Julia interface for downloading ERA5 and ERA5-Land data.

## Features

- Download ERA5 single-level hourly data to NetCDF or GRIB
- Subset by time (year, month, day, hour) and space (bounding box)
- Simple Julia API that wraps the `era5cli` command-line tool

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

## Contents

```@contents
Pages = ["quickstart.md"]
Depth = 2
```

