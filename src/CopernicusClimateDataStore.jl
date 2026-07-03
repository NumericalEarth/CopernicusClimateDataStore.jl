module CopernicusClimateDataStore

export retrieve, read_cds_credentials, CDSCredentials
export submit_cds_request, poll_request_status, download_cds_file
export hourly, monthly, yearly

include("cds_client.jl")

"""
    hourly(; variables, startyear, months, days, hours, area=nothing,
           pressure_levels=nothing, format="netcdf", outputprefix="era5",
           overwrite=false, threads=Threads.nthreads(), splitmonths=false, directory=".",
           additional_kw...)

Download ERA5 hourly data using the CDS API. This function provides compatibility
with NumericalEarth's ERA5 download interface.

# Arguments
- `pressure_levels`: Optional pressure levels in hPa (e.g., [1000, 850, 500]).
                     If provided, downloads from pressure-levels dataset instead of single-levels.

Returns a vector of downloaded file paths.
"""
function hourly(; variables::String, startyear::Int, months, days, hours,
                  area=nothing, pressure_levels=nothing, format::String="netcdf",
                  outputprefix::String="era5", overwrite::Bool=false,
                  threads::Int=Threads.nthreads(), splitmonths::Bool=false,
                  directory::String=".", additional_kw...)

    # Convert single values to arrays
    months_arr = months isa AbstractVector ? months : [months]
    days_arr = days isa AbstractVector ? days : [days]
    hours_arr = hours isa AbstractVector ? hours : [hours]

    # Format hours as two-digit strings
    hours_str = [string(h, pad=2) * ":00" for h in hours_arr]

    # Format date strings
    dates_str = String[]
    for month in months_arr, day in days_arr
        push!(dates_str, string(startyear, "-", string(month, pad=2), "-", string(day, pad=2)))
    end

    # Build request parameters
    request_params = Dict(
        "product_type" => "reanalysis",
        "format" => format,
        "variable" => variables,
        "year" => string(startyear),
        "month" => [string(m, pad=2) for m in months_arr],
        "day" => [string(d, pad=2) for d in days_arr],
        "time" => hours_str
    )

    # Add area if specified - CDS API v2 expects [north, west, south, east] format
    if area !== nothing
        # Convert from (lat=(south,north), lon=(west,east)) to [north, west, south, east]
        if area isa NamedTuple && haskey(area, :lat) && haskey(area, :lon)
            lat_min, lat_max = area.lat
            lon_min, lon_max = area.lon
            request_params["area"] = [lat_max, lon_min, lat_min, lon_max]
        else
            # Assume already in correct format
            request_params["area"] = area
        end
    end

    # Add pressure levels if specified (for pressure-level datasets)
    if pressure_levels !== nothing
        pl_arr = pressure_levels isa AbstractVector ? pressure_levels : [pressure_levels]
        request_params["pressure_level"] = [string(Int(p)) for p in pl_arr]
    end

    # Generate output filename
    mkpath(directory)

    # If requesting single date/hour, use outputprefix as-is (for NumericalEarth compatibility)
    # Otherwise append date for batched downloads
    if length(months_arr) == 1 && length(days_arr) == 1 && length(hours_arr) == 1
        output_file = joinpath(directory, "$(outputprefix).nc")
    else
        output_file = joinpath(directory, "$(outputprefix)_$(startyear)_$(first(months_arr))_$(first(days_arr)).nc")
    end

    # Skip if file exists and not overwriting
    if isfile(output_file) && !overwrite
        return [output_file]
    end

    # Submit download request
    dataset_id = pressure_levels === nothing ? "reanalysis-era5-single-levels" : "reanalysis-era5-pressure-levels"
    retrieve(dataset_id, request_params, output_file)

    return [output_file]
end

"""
    monthly(; variables, year, month, area=nothing, pressure_levels=nothing,
            format="netcdf", outputprefix="era5_monthly", directory=pwd(),
            overwrite=false, threads=Threads.nthreads(), additional_kw...)

Download full month(s) of ERA5 data in single files per variable.

Downloads all days (1-31) and all hours (0-23) for each month in one CDS API
request per variable per month. This is 720× faster than downloading hourly
files individually.

# Arguments
- `variables`: Variable name(s) - String or Vector{String}
- `year`: Year to download - Integer or Vector{Integer}
- `month`: Month(s) to download - Integer (1-12) or Vector{Integer}
- `area`: [south, west, north, east] bounding box (optional)
- `pressure_levels`: Optional pressure levels in hPa (e.g., [1000, 850, 500])
- `format`: Output format (default: "netcdf")
- `outputprefix`: Base filename prefix (default: "era5_monthly")
- `directory`: Output directory (default: pwd())
- `overwrite`: Overwrite existing files (default: false)
- `threads`: Number of download threads (default: 1)

# Returns
Vector of paths to downloaded files

# Example
```julia
# Download January 2020 temperature for Bouvet region
files = monthly(;
    variables = "2m_temperature",
    year = 2020,
    month = 1,
    area = [-51, -6, -58, 11],  # [south, west, north, east]
    directory = "/data/ERA5_monthly"
)

# Download multiple months
files = monthly(;
    variables = "2m_temperature",
    year = 2020,
    month = 1:3,  # Jan, Feb, Mar
    directory = "/data/ERA5_monthly"
)
```

# File naming
Creates files: `variable_YYYY_MM_bbox.nc` or `variable_YYYY_MM.nc` (global)
Example: `2m_temperature_2020_01_-51_-6_-58_11.nc`

# Performance
One month contains ~720-744 hourly timesteps (28-31 days * 24 hours).
Download time depends on region size and CDS queue load.
Smaller regions download faster; global datasets take longer.
"""
function monthly(;
    variables,
    year,
    month,
    area = nothing,
    pressure_levels = nothing,
    format = "netcdf",
    outputprefix = "era5_monthly",
    directory = pwd(),
    overwrite = false,
    threads = Threads.nthreads(),
    additional_kw...
)
    # Normalize inputs to vectors
    var_list = variables isa String ? [variables] : collect(variables)
    year_list = year isa Integer ? [year] : collect(year)
    month_list = month isa Integer ? [month] : collect(month)

    results = String[]

    for yr in year_list
        for mon in month_list
            for var in var_list
                # Build filename with bounding box coordinates
                bbox_str = if isnothing(area)
                    ""
                else
                    # area format: [south, west, north, east]
                    # Store as: _lon1_lon2_lat1_lat2 for clarity
                    if length(area) == 4
                        "_$(area[2])_$(area[4])_$(area[1])_$(area[3])"
                    else
                        ""
                    end
                end

                filename = "$(var)_$(yr)_$(lpad(mon, 2, '0'))$(bbox_str).nc"
                output_path = joinpath(directory, filename)

                # Skip if exists and not overwriting
                if !overwrite && isfile(output_path)
                    push!(results, output_path)
                    continue
                end

                # Build CDS API request parameters for FULL MONTH
                # All days (1-31), all hours (0-23) in ONE request
                params = Dict{String, Any}(
                    "product_type" => "reanalysis",
                    "variable" => [var],
                    "year" => [string(yr)],
                    "month" => [lpad(mon, 2, '0')],
                    "day" => string.(1:31, pad=2),    # ["01", "02", ..., "31"]
                    "time" => [string(h, pad=2) * ":00" for h in 0:23],  # ["00:00", ..., "23:00"]
                    "format" => format == "netcdf" ? "netcdf" : "grib"
                )

                # Add area constraint if specified
                if !isnothing(area) && length(area) == 4
                    # CDS API expects [north, west, south, east]
                    params["area"] = [area[3], area[2], area[1], area[4]]
                end

                # Add pressure levels if specified
                if !isnothing(pressure_levels)
                    pl_arr = pressure_levels isa AbstractVector ? pressure_levels : [pressure_levels]
                    params["pressure_level"] = [string(Int(p)) for p in pl_arr]
                end

                region_str = isnothing(area) ? "global" : "regional"
                dataset_str = isnothing(pressure_levels) ? "single-levels" : "pressure-levels"
                @info "Downloading $var for $(yr)-$(lpad(mon, 2, '0')) ($dataset_str, $region_str)..."

                # Download using direct CDS API
                dataset_id = isnothing(pressure_levels) ? "reanalysis-era5-single-levels" : "reanalysis-era5-pressure-levels"
                retrieve(dataset_id,
                        params,
                        output_path;
                        max_wait = 3600,
                        poll_interval = 10,
                        verbose = true)

                push!(results, output_path)
                file_size_mb = round(filesize(output_path)/1e6, digits=1)
                @info "  ✓ Downloaded $(basename(output_path)) ($file_size_mb MB)"
            end
        end
    end

    return results
end

"""
    yearly(; variables, years, area=nothing, pressure_levels=nothing,
           format="netcdf", outputprefix="era5_yearly", directory=pwd(),
           overwrite=false, threads=Threads.nthreads(), additional_kw...)

Download full year(s) of ERA5 data in single files per variable.

Downloads all months (1-12), all days (1-31), and all hours (0-23) for each
year in one CDS API request per variable per year. This is 8760× faster than
downloading hourly files individually.

# Arguments
- `variables`: Variable name(s) - String or Vector{String}
- `years`: Year(s) to download - Integer or range (e.g., 2000 or 2000:2010)
- `area`: [north, west, south, east] bounding box (optional)
- `pressure_levels`: Optional pressure levels in hPa (e.g., [1000, 850, 500])
- `format`: Output format (default: "netcdf")
- `outputprefix`: Base filename prefix (default: "era5_yearly")
- `directory`: Output directory (default: pwd())
- `overwrite`: Overwrite existing files (default: false)
- `threads`: Number of download threads (default: 1)

# Returns
Vector of paths to downloaded files

# Example
```julia
# Download 2000-2010 temperature for Bouvet region
files = yearly(;
    variables = "2m_temperature",
    years = 2000:2010,
    area = [-51, -6, -58, 11],  # [south, west, north, east]
    directory = "/data/ERA5_yearly"
)
```

# File naming
Creates files: `variable_YYYY_bbox.nc` or `variable_YYYY.nc` (global)
Example: `2m_temperature_2000_-51_-6_-58_11.nc`

# Performance
One year contains 8760-8784 hourly timesteps (regular/leap year).
Download time depends on region size and CDS queue load.
Smaller regions download faster; global datasets take longer.
"""
function yearly(;
    variables,
    years,
    area = nothing,
    pressure_levels = nothing,
    format = "netcdf",
    outputprefix = "era5_yearly",
    directory = pwd(),
    overwrite = false,
    threads = Threads.nthreads(),
    additional_kw...
)
    # Normalize inputs to vectors
    var_list = variables isa String ? [variables] : collect(variables)
    year_list = years isa Integer ? [years] : collect(years)

    results = String[]

    for year in year_list
        for var in var_list
            # Build filename with bounding box coordinates
            bbox_str = if isnothing(area)
                ""
            else
                # area format: [south, west, north, east] or [north, west, south, east]
                # Store as: _lon1_lon2_lat1_lat2 for clarity
                if length(area) == 4
                    "_$(area[2])_$(area[4])_$(area[1])_$(area[3])"
                else
                    ""
                end
            end

            filename = "$(var)_$(year)$(bbox_str).nc"
            output_path = joinpath(directory, filename)

            # Skip if exists and not overwriting
            if !overwrite && isfile(output_path)
                push!(results, output_path)
                continue
            end

            # Build CDS API request parameters for FULL YEAR
            # All months, all days, all hours in ONE request
            params = Dict{String, Any}(
                "product_type" => "reanalysis",
                "variable" => [var],
                "year" => [string(year)],
                "month" => string.(1:12, pad=2),  # ["01", "02", ..., "12"]
                "day" => string.(1:31, pad=2),    # ["01", "02", ..., "31"]
                "time" => [string(h, pad=2) * ":00" for h in 0:23],  # ["00:00", ..., "23:00"]
                "format" => format == "netcdf" ? "netcdf" : "grib"
            )

            # Add area constraint if specified
            if !isnothing(area) && length(area) == 4
                # CDS API expects [north, west, south, east]
                params["area"] = [area[3], area[2], area[1], area[4]]
            end

            # Add pressure levels if specified
            if !isnothing(pressure_levels)
                pl_arr = pressure_levels isa AbstractVector ? pressure_levels : [pressure_levels]
                params["pressure_level"] = [string(Int(p)) for p in pl_arr]
            end

            region_str = isnothing(area) ? "global" : "regional"
            dataset_str = isnothing(pressure_levels) ? "single-levels" : "pressure-levels"
            @info "Downloading $var for year $year ($dataset_str, $region_str)..."

            # Download using direct CDS API
            dataset_id = isnothing(pressure_levels) ? "reanalysis-era5-single-levels" : "reanalysis-era5-pressure-levels"
            retrieve(dataset_id,
                    params,
                    output_path;
                    max_wait = 3600,
                    poll_interval = 10,
                    verbose = true)

            push!(results, output_path)
            file_size_mb = round(filesize(output_path)/1e6, digits=1)
            @info "  ✓ Downloaded $(basename(output_path)) ($file_size_mb MB)"
        end
    end

    return results
end


end # module CopernicusClimateDataStore
