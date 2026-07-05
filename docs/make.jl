const root = @__DIR__

import Pkg
Pkg.develop(Pkg.PackageSpec(path = joinpath(root, "..")))
Pkg.instantiate()

using Documenter
using QuickCharts

repo_slug = get(ENV, "GITHUB_REPOSITORY", "NumericalForge/QuickCharts.jl")
repo_url = "https://github.com/$(repo_slug)"

makedocs(
    root = root,
    modules = [QuickCharts],
    sitename = "QuickCharts.jl",
    pagesonly = true,
    checkdocs = :exports,
    doctest = true,
    remotes = nothing,
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        collapselevel = 1,
        repolink = repo_url,
    ),
    pages = [
        "Introduction" => "index.md",
        "Manual" => [
            "Getting Started" => "manual/getting-started.md",
            "Chart Tutorial" => "tutorial/chart-basics.md",
            "Field Plots Tutorial" => "tutorial/field-plots.md",
            "ChartGrid Tutorial" => "tutorial/chart-grid.md",
        ],
        "API Reference" => [
            "Reference" => "api/reference.md",
        ],
    ],
)

deploydocs(
    devbranch = "main",
    target = "build",
    branch = "gh-pages",
    repo = "github.com/$(repo_slug).git",
)
