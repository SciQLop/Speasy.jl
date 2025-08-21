using Documenter, Speasy

DocMeta.setdocmeta!(Speasy, :DocTestSetup, :(using Speasy))

makedocs(
    sitename = "Speasy.jl",
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    modules = [Speasy],
    pages = [
        "Home" => "index.md",
        "Tutorial" => "tutorial.md",
        "API Reference" => "api.md",
    ],
    warnonly = Documenter.except(:doctest),
)

deploydocs(
    repo = "github.com/SciQLop/Speasy.jl",
    push_preview = true
)
