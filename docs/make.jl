using ExpressionData
using Documenter

DocMeta.setdocmeta!(ExpressionData, :DocTestSetup, :(using ExpressionData); recursive=true)

makedocs(;
         modules=[ExpressionData],
         authors="Chris Damour",
         sitename="ExpressionData.jl",
         format=Documenter.HTML(;
                                canonical="https://damourChris.github.io/ExpressionData.jl",
                                edit_link="main",
                                assets=String[],),
         pages=["Home" => "index.md",
                "ExpressionSet" => "expression_set.md",
                "MIAME" => "miame.jl",
                "Saving / Loading" => "io.jl"],)

deploydocs(;
           repo="github.com/damourChris/ExpressionData.jl",
           devbranch="main",)
