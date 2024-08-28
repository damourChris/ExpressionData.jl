using BioData
using Documenter

DocMeta.setdocmeta!(BioData, :DocTestSetup, :(using BioData); recursive=true)

makedocs(;
    modules=[BioData],
    authors="Chris Damour",
    sitename="BioData.jl",
    format=Documenter.HTML(;
        canonical="https://damourChris.github.io/BioData.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/damourChris/BioData.jl",
    devbranch="main",
)
