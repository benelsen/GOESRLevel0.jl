using GOESRLevel0
using Documenter

makedocs(;
    sitename="GOESRLevel0.jl",
    authors="Ben Elsen <mail@benelsen.com>",
    modules=[GOESRLevel0],
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://benelsen.github.io/GOESRLevel0.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Guide" => "guide.md",
        "Data" => "data.md",
        "Library" => "library.md",
    ],
    repo="https://github.com/benelsen/GOESRLevel0.jl/blob/{commit}{path}#L{line}",
)

deploydocs(;
    repo="github.com/benelsen/GOESRLevel0.jl",
)
