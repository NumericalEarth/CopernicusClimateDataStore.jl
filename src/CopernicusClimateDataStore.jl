module CopernicusClimateDataStore

using CondaPkg

export install_era5cli, era5cli_cmd, hourly, monthly, info

#####
##### Installation and CLI location
#####

"""
    install_era5cli()

Install the `era5cli` command-line tool (version ≥ 2.0.1) using CondaPkg.
Returns the path to the installed CLI executable.

Note: The old Climate Data Store (CDS) was shut down on 3 September 2024.
All era5cli versions up to v1.4.2 no longer work. This function installs
a compatible version.
"""
function install_era5cli()
    @info "Installing era5cli via CondaPkg..."
    # era5cli is available via pip; we install it in the Conda environment
    CondaPkg.add_pip("era5cli"; version=">=2.0.1")
    cli = era5cli_cmd()
    @info "era5cli installed at: $cli"
    return cli
end

"""
    era5cli_cmd()

Return the absolute path to the `era5cli` executable.
If not found, attempts to install it first.
"""
function era5cli_cmd()
    cli = CondaPkg.which("era5cli")
    if isnothing(cli)
        @warn "era5cli not found. Attempting to install..."
        CondaPkg.add_pip("era5cli"; version=">=2.0.1")
        cli = CondaPkg.which("era5cli")
        if isnothing(cli)
            error("Failed to locate era5cli after installation. " *
                  "Please check your CondaPkg configuration.")
        end
    end
    return cli
end

#####
##### Area/bounding box utilities
#####

"""
    format_area(area)

Convert a bounding box specification to the format required by era5cli:
`LAT_MAX LON_MIN LAT_MIN LON_MAX` (counterclockwise starting at top).

Accepts:
- `nothing` → returns `nothing` (no area constraint)
- A tuple/vector of 4 numbers in era5cli order: `(lat_max, lon_min, lat_min, lon_max)`
- A NamedTuple with keys `lat` and `lon`, each a tuple of (min, max):
  `(lat=(lat_min, lat_max), lon=(lon_min, lon_max))`
"""
function format_area(area::Nothing)
    return nothing
end

function format_area(area::NTuple{4, <:Real})
    # Assume already in era5cli order: (lat_max, lon_min, lat_min, lon_max)
    return area
end

function format_area(area::AbstractVector{<:Real})
    length(area) == 4 || error("Area vector must have exactly 4 elements: " *
                               "[lat_max, lon_min, lat_min, lon_max]")
    return Tuple(area)
end

function format_area(area::NamedTuple{(:lat, :lon)})
    lat_min, lat_max = area.lat
    lon_min, lon_max = area.lon
    # era5cli order: LAT_MAX LON_MIN LAT_MIN LON_MAX
    return (lat_max, lon_min, lat_min, lon_max)
end

# Also accept reversed key order
function format_area(area::NamedTuple{(:lon, :lat)})
    return format_area((lat=area.lat, lon=area.lon))
end

#####
##### Command building utilities
#####

"""
    build_hourly_cmd(; kwargs...)

Build the command-line arguments for `era5cli hourly`.
Returns a `Cmd` object ready to be executed.

The `cli` keyword can be used to override the path to the era5cli executable
(useful for testing command construction without installing era5cli).
"""
function build_hourly_cmd(;
        variables,
        startyear::Integer,
        endyear::Integer = startyear,
        months = nothing,
        days = nothing,
        hours = nothing,
        area = nothing,
        format::String = "netcdf",
        outputprefix::String = "era5",
        overwrite::Bool = true,
        threads::Integer = 1,
        splitmonths::Bool = true,
        merge::Bool = false,
        dryrun::Bool = false,
        land::Bool = false,
        ensemble::Bool = false,
        levels = nothing,
        statistics::Bool = false,
        cli::Union{String, Nothing} = nothing,  # For testing without installing
    )

    if isnothing(cli)
        cli = era5cli_cmd()
    end
    args = String[cli, "hourly"]

    # Variables (required)
    if variables isa AbstractString
        variables = [variables]
    end
    push!(args, "--variables")
    append!(args, string.(variables))

    # Year range
    push!(args, "--startyear", string(startyear))
    if endyear != startyear
        push!(args, "--endyear", string(endyear))
    end

    # Optional time filters
    if !isnothing(months)
        push!(args, "--months")
        append!(args, string.(months isa Integer ? [months] : months))
    end

    if !isnothing(days)
        push!(args, "--days")
        append!(args, string.(days isa Integer ? [days] : days))
    end

    if !isnothing(hours)
        push!(args, "--hours")
        append!(args, string.(hours isa Integer ? [hours] : hours))
    end

    # Area constraint
    formatted_area = format_area(area)
    if !isnothing(formatted_area)
        push!(args, "--area")
        append!(args, string.(formatted_area))
    end

    # Pressure levels (for 3D variables)
    if !isnothing(levels)
        push!(args, "--levels")
        if levels isa AbstractString || levels isa Symbol
            push!(args, string(levels))
        else
            append!(args, string.(levels))
        end
    end

    # Output options
    push!(args, "--format", format)
    push!(args, "--outputprefix", outputprefix)
    push!(args, "--threads", string(threads))

    # Boolean flags
    if overwrite
        push!(args, "--overwrite")
    end

    if merge
        push!(args, "--merge")
    end

    if !splitmonths
        push!(args, "--splitmonths", "False")
    end

    if dryrun
        push!(args, "--dryrun")
    end

    if land
        push!(args, "--land")
    end

    if ensemble
        push!(args, "--ensemble")
    end

    if statistics
        push!(args, "--statistics")
    end

    return Cmd(args)
end

#####
##### High-level API
#####

"""
    hourly(; variables, startyear, kwargs...) -> Vector{String}

Download ERA5 hourly data using `era5cli`.

# Required Arguments
- `variables`: Variable name(s) to download. Can be a string or vector of strings.
  Examples: `"2m_temperature"`, `["2m_temperature", "total_precipitation"]`
- `startyear`: First year to download (integer).

# Optional Arguments
- `endyear`: Last year to download (default: same as `startyear`).
- `months`: Month(s) to download (1-12). Default: all months.
- `days`: Day(s) to download (1-31). Default: all days.
- `hours`: Hour(s) to download (0-23). Default: all hours.
- `area`: Bounding box for spatial subsetting. Can be:
  - A tuple `(lat_max, lon_min, lat_min, lon_max)` in era5cli order
  - A NamedTuple `(lat=(south, north), lon=(west, east))`
- `format`: Output format, `"netcdf"` (default) or `"grib"`.
- `outputprefix`: Prefix for output filenames (default: `"era5"`).
- `overwrite`: Overwrite existing files without prompting (default: `true`).
- `threads`: Number of parallel download threads (default: `1`).
- `splitmonths`: Split output by months (default: `true`).
- `merge`: Merge all output into a single file (default: `false`).
- `dryrun`: Print the request without downloading (default: `false`).
- `land`: Download from ERA5-Land dataset (default: `false`).
- `ensemble`: Download ensemble data instead of HRES (default: `false`).
- `levels`: Pressure level(s) for 3D variables, or `:surface` for surface geopotential.
- `statistics`: Download ensemble statistics (default: `false`).
- `directory`: Directory to download files into (default: current directory).

# Returns
- If `dryrun=true`: the `Cmd` object that would be executed.
- Otherwise: a `Vector{String}` of paths to the downloaded file(s).

# Output Files
By default, `era5cli` creates one file per month (`splitmonths=true`). If you request
multiple months, you will receive multiple files. Use `merge=true` to combine all
data into a single file, or `splitmonths=false` to get one file per variable.

# Example
```julia
using CopernicusClimateDataStore

# Download 2m temperature for a single day
files = hourly(variables="2m_temperature",
               startyear=2020,
               months=1,
               days=1,
               hours=12,
               area=(lat=(40, 50), lon=(-10, 10)),
               format="netcdf")

# files[1] contains the path to the downloaded NetCDF file
```

# CDS Setup Required
Before downloading, you must:
1. Create an account at https://cds.climate.copernicus.eu/
2. Accept the Terms of Use for the ERA5 dataset on the dataset page
3. Configure your API key with `era5cli config --key YOUR_KEY`

See https://cds.climate.copernicus.eu/how-to-api for details.
"""
function hourly(; variables, startyear, directory::String = pwd(), kwargs...)
    cmd = build_hourly_cmd(; variables, startyear, kwargs...)

    dryrun = get(kwargs, :dryrun, false)
    if dryrun
        @info "Dry run - command that would be executed:"
        println(cmd)
        return cmd
    end

    # Get the output prefix and format to identify new files
    outputprefix = get(kwargs, :outputprefix, "era5")
    format = get(kwargs, :format, "netcdf")
    extension = format == "netcdf" ? ".nc" : ".grib"

    # List existing files before download
    files_before = Set(readdir(directory))

    # Run the download in the specified directory
    @info "Running era5cli hourly download..."
    cd(directory) do
        run(cmd)
    end

    # Find new files that match the prefix and extension
    files_after = Set(readdir(directory))
    new_files = setdiff(files_after, files_before)
    
    # Filter to files matching our prefix and extension
    downloaded = filter(new_files) do f
        startswith(f, outputprefix) && endswith(f, extension)
    end

    # Return full paths, sorted for consistency
    paths = sort([joinpath(directory, f) for f in downloaded])
    
    @info "Downloaded $(length(paths)) file(s)"
    return paths
end

"""
    monthly(; variables, startyear, kwargs...)
Download ERA5 monthly-averaged data using `era5cli`.

Arguments are similar to [`hourly`](@ref), but downloads monthly means instead
of hourly data. See `era5cli monthly --help` for full details.
"""
function monthly(; variables, startyear, kwargs...)
    # Build similar to hourly but with "monthly" subcommand
    cli = era5cli_cmd()
    
    # For now, delegate to hourly with a note that this should be separate
    error("monthly() not yet implemented - use hourly() or call era5cli directly")
end

"""
    info(; what=:variables, land=false, levels=false)

Display information about available ERA5 variables or pressure levels.

# Arguments
- `what`: What to show - `:variables` (default), `:levels`, or a specific variable name.
- `land`: Show ERA5-Land variables instead of ERA5 (default: `false`).
- `levels`: Show available pressure levels (default: `false`).
"""
function info(; what=:variables, land::Bool=false, levels::Bool=false)
    cli = era5cli_cmd()
    args = [cli, "info"]

    if levels || what == :levels
        push!(args, "--levels")
    elseif what isa AbstractString
        push!(args, what)
    end

    if land
        push!(args, "--land")
    end

    run(Cmd(args))
    return nothing
end

end # module CopernicusClimateDataStore
