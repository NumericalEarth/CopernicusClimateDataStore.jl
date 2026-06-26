# Pure Julia CDS (Copernicus Climate Data Store) API client
# Compatible with new CDS API (post-September 2024 migration)

using HTTP
using JSON3
using Downloads
using Dates
using Base64

"""
    CDSCredentials

Stores Copernicus Climate Data Store API credentials (URL and API key).

# Fields
- `url::String`: CDS API endpoint URL (e.g., "https://cds.climate.copernicus.eu/api")
- `key::String`: Your personal CDS API key

# Example
```julia
creds = CDSCredentials("https://cds.climate.copernicus.eu/api", "your-api-key")
```

Typically obtained automatically via `read_cds_credentials()`.
"""
struct CDSCredentials
    url::String
    key::String
end

"""
    read_cds_credentials(config_path=nothing)

Read CDS API credentials from:
1. Explicit config_path
2. Environment variables: CDSAPI_URL, CDSAPI_KEY
3. ~/.cdsapirc (standard location)
4. ~/.config/era5cli/cds_key.txt (era5cli location)
"""
function read_cds_credentials(config_path=nothing)
    # Priority 1: Explicit config path
    if !isnothing(config_path) && isfile(config_path)
        return parse_cdsapi_rc(config_path)
    end

    # Priority 2: Environment variables
    if haskey(ENV, "CDSAPI_URL") && haskey(ENV, "CDSAPI_KEY")
        return CDSCredentials(ENV["CDSAPI_URL"], ENV["CDSAPI_KEY"])
    end

    # Priority 3: ~/.cdsapirc (standard)
    default_rc = joinpath(homedir(), ".cdsapirc")
    if isfile(default_rc)
        return parse_cdsapi_rc(default_rc)
    end

    # Priority 4: era5cli config
    era5cli_config = joinpath(homedir(), ".config", "era5cli", "cds_key.txt")
    if isfile(era5cli_config)
        return parse_cdsapi_rc(era5cli_config)
    end

    error("""
    CDS credentials not found. Please create ~/.cdsapirc with:
    url: https://cds.climate.copernicus.eu/api
    key: <your-api-key>

    Or set environment variables CDSAPI_URL and CDSAPI_KEY.
    Register at: https://cds.climate.copernicus.eu/
    """)
end

function parse_cdsapi_rc(path::String)
    lines = readlines(path)
    url = ""
    key = ""

    for line in lines
        line = strip(line)
        isempty(line) && continue
        startswith(line, '#') && continue

        if contains(line, ':')
            parts = split(line, ':', limit=2)
            key_part = strip(parts[1])
            val_part = strip(parts[2])

            if key_part == "url"
                url = val_part
            elseif key_part == "key"
                key = val_part
            end
        end
    end

    isempty(url) && error("No 'url' found in $path")
    isempty(key) && error("No 'key' found in $path")

    return CDSCredentials(url, key)
end

"""
    submit_cds_request(credentials, dataset, params)

Submit download request to CDS API v2. Returns status endpoint URL.
"""
function submit_cds_request(credentials::CDSCredentials, dataset::String, params::Dict)
    # New CDS API v2 endpoint structure
    endpoint = "$(credentials.url)/retrieve/v1/processes/$(dataset)/execute"

    headers = [
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "PRIVATE-TOKEN" => credentials.key  # v2 uses PRIVATE-TOKEN, not Authorization
    ]

    # v2 requires params wrapped in "inputs"
    body = JSON3.write(Dict("inputs" => params))

    response = HTTP.post(endpoint, headers, body)

    # Extract status endpoint from Location header
    location = String(Dict(response.headers)["location"])

    return location
end

"""
    poll_request_status(credentials, status_endpoint; max_wait=3600, poll_interval=5, verbose=true)

Poll CDS request status until completion or timeout.
Returns download URL when ready.
"""
function poll_request_status(credentials::CDSCredentials, status_endpoint::String;
                             max_wait=3600, poll_interval=5, verbose=true)
    headers = ["PRIVATE-TOKEN" => credentials.key]

    start_time = time()
    last_status = ""

    while time() - start_time < max_wait
        response = HTTP.get(status_endpoint, headers)
        result = JSON3.read(String(response.body))

        status = result.status

        if verbose && status != last_status
            @info "CDS request: $status"
            last_status = status
        end

        if status == "successful"
            # Download URL is {status_endpoint}/results
            return status_endpoint * "/results"
        elseif status == "failed"
            error("CDS request failed. Check https://cds.climate.copernicus.eu/requests for details.")
        end

        sleep(poll_interval)
    end

    error("Request timed out after $(max_wait)s")
end

"""
    download_cds_file(url, output_path; credentials)

Download file from CDS result URL.
"""
function download_cds_file(url::String, output_path::String, credentials::CDSCredentials)
    mkpath(dirname(output_path))

    # Add authentication header
    headers = ["PRIVATE-TOKEN" => credentials.key]
    Downloads.download(url, output_path; headers)

    @info "Downloaded: $output_path ($(filesize(output_path)) bytes)"
    return output_path
end

"""
    retrieve(dataset, params, output_path; credentials=nothing, max_wait=3600, poll_interval=10, verbose=true)

Download data from Copernicus Climate Data Store using CDS API v2.

# Arguments
- `dataset`: CDS dataset name (e.g., "reanalysis-era5-single-levels")
- `params`: Dict with CDS API parameters (product_type, variable, year, month, day, time, etc.)
- `output_path`: Where to save the downloaded NetCDF file
- `credentials`: CDSCredentials object, or nothing to auto-detect
- `max_wait`: Maximum wait time for request (seconds)
- `poll_interval`: How often to check request status (seconds)
- `verbose`: Print progress messages

# Example
```julia
params = Dict(
    "product_type" => "reanalysis",
    "variable" => ["2m_temperature"],
    "year" => ["2020"],
    "month" => ["01"],
    "day" => ["01"],
    "time" => ["00:00", "12:00"],
    "format" => "netcdf"
)

retrieve("reanalysis-era5-single-levels", params, "output.nc")
```

# Returns
Path to downloaded file
"""
function retrieve(dataset::String,
                 params::Dict,
                 output_path::String;
                 credentials=nothing,
                 max_wait=3600,
                 poll_interval=10,
                 verbose=true)

    # Get credentials
    creds = isnothing(credentials) ? read_cds_credentials() : credentials

    if verbose
        nvars = length(get(params, "variable", []))
        @info "Submitting CDS request: $dataset ($nvars variables)"
    end

    # Submit request - returns status endpoint URL
    status_endpoint = submit_cds_request(creds, dataset, params)

    if verbose
        @info "Request submitted, polling for completion..."
    end

    # Poll until ready - returns download URL
    download_url = poll_request_status(creds, status_endpoint;
                                       max_wait, poll_interval, verbose)

    # Download file
    download_cds_file(download_url, output_path, creds)

    return output_path
end
