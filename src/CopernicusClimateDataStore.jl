module CopernicusClimateDataStore

export retrieve, read_cds_credentials, CDSCredentials
export submit_cds_request, poll_request_status, download_cds_file

include("cds_client.jl")

"""
    hourly(; variables, startyear, months, days, hours, area=nothing,
           format="netcdf", outputprefix="era5", overwrite=false,
           threads=1, splitmonths=false, directory=".", additional_kw...)

Download ERA5 hourly data using the CDS API. This function provides compatibility
with NumericalEarth's ERA5 download interface.

Returns a vector of downloaded file paths.
"""
function hourly(; variables::String, startyear::Int, months, days, hours,
                  area=nothing, format::String="netcdf",
                  outputprefix::String="era5", overwrite::Bool=false,
                  threads::Int=1, splitmonths::Bool=false,
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
    dataset_id = "reanalysis-era5-single-levels"
    retrieve(dataset_id, request_params, output_file)

    return [output_file]
end


end # module CopernicusClimateDataStore
