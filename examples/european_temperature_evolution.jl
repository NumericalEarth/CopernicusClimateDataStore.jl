# # European Temperature Evolution
#
# This example downloads ERA5 2m temperature data for Europe over a 24-hour period,
# loads the NetCDF file, and creates an animation showing temperature evolution.

using CopernicusClimateDataStore
using NCDatasets
using CairoMakie

# ## Download ERA5 data
#
# We download 2m temperature for January 15, 2020 — all 24 hours — over Europe.

files = hourly(
    variables = "2m_temperature",
    startyear = 2020,
    months = 1,
    days = 15,
    area = (lat = (35, 70), lon = (-15, 40)),
    format = "netcdf",
    outputprefix = "europe_t2m"
)

filename = first(files)
@info "Downloaded: $filename ($(filesize(filename)) bytes)"

# ## Load the data
#
# Open the NetCDF file and extract coordinates and temperature.

ds = NCDataset(filename)

lon = ds["longitude"][:]
lat = ds["latitude"][:]
time = ds["time"][:]
t2m = ds["t2m"][:, :, :]  # (lon, lat, time)

close(ds)

# Convert temperature from Kelvin to Celsius.

temp_C = t2m .- 273.15

Nt = length(time)
@info "Loaded $Nt time steps from $(time[1]) to $(time[end])"

# ## Create the animation
#
# We animate temperature evolution over the 24-hour period.

fig = Figure(size = (900, 700))

ax = Axis(fig[1, 1],
    xlabel = "Longitude (°)",
    ylabel = "Latitude (°)",
    aspect = DataAspect()
)

n = Observable(1)

temp_n = @lift temp_C[:, :, $n]'
title = @lift "ERA5 2m Temperature — $(time[$n])"

Label(fig[0, :], title, fontsize = 18)

hm = heatmap!(ax, lon, lat, temp_n,
    colormap = :thermal,
    colorrange = (-20, 25)
)

Colorbar(fig[1, 2], hm, label = "Temperature (°C)")

fig

# Record the animation.

CairoMakie.record(fig, "european_temperature.mp4", 1:Nt, framerate = 4) do nn
    n[] = nn
end
nothing #hide

# ![](european_temperature.mp4)

