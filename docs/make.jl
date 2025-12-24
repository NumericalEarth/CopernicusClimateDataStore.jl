using CopernicusClimateDataStore
using Documenter
using CairoMakie

CairoMakie.activate!(type = "png")

examples_src_dir = joinpath(@__DIR__, "..", "examples")
literated_dir = joinpath(@__DIR__, "src", "literated")
mkpath(literated_dir)

# Build literated examples
examples = [
    ("European temperature evolution", "european_temperature_evolution"),
]

for (title, basename) in examples
    script_path = joinpath(examples_src_dir, basename * ".jl")
    @info "Building example: $title"
    run(`$(Base.julia_cmd()) --project=$(dirname(Base.active_project())) $(joinpath(@__DIR__, "literate.jl")) $script_path $literated_dir`)
end

example_pages = [title => joinpath("literated", basename * ".md") for (title, basename) in examples]

makedocs(
    sitename = "CopernicusClimateDataStore.jl",
    modules = [CopernicusClimateDataStore],
    format = Documenter.HTML(
        size_threshold_warn = 2^19,
        size_threshold = 2^20,
    ),
    pages = [
        "Home" => "index.md",
        "Quick Start" => "quickstart.md",
        "Examples" => example_pages,
    ],
)

