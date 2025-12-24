using Documenter

@info "Cleaning up temporary files..."

for (root, _, filenames) in walkdir(@__DIR__)
    for file in filenames
        if any(ext -> endswith(file, ext), (".jld2", ".nc", ".grib"))
            rm(joinpath(root, file); force=true)
        end
    end
end

deploydocs(
    repo = "github.com/NumericalEarth/CopernicusClimateDataStore.jl",
    devbranch = "main",
    push_preview = true,
    forcepush = true,
)

