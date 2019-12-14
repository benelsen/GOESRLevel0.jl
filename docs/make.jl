using Documenter, GOESRLevel0

makedocs(;
    modules=[GOESRLevel0],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/benelsen/GOESRLevel0.jl/blob/{commit}{path}#L{line}",
    sitename="GOESRLevel0.jl",
    authors="Ben Elsen <mail@benelsen.com>",
    assets=String[],
)

deploydocs(;
    repo="github.com/benelsen/GOESRLevel0.jl",
)
