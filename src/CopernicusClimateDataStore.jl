module CopernicusClimateDataStore

export retrieve, read_cds_credentials, CDSCredentials
export submit_cds_request, poll_request_status, download_cds_file

include("cds_client.jl")

"""
    hourly()

Return a tuple of hourly frequency indicator for ERA5 downloads.
"""
hourly() = ("hourly",)


end # module CopernicusClimateDataStore
