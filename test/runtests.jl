using ExpressionData
using DataFrames
using Serialization
using Test

# Test data definitions - pure Julia implementation
test_miame = MIAME(;
                   name="Name",
                   lab="Lab",
                   contact="Contact",
                   title="Title",
                   abstract="Abstract",
                   url="URL",
                   samples=["Sample1", "Sample2"],
                   hybridizations=["Hybridization1", "Hybridization2"],
                   norm_controls=["Control1", "Control2"],
                   preprocessing=["Preprocessing1", "Preprocessing2"],
                   pub_med_id="ID1",
                   other=Dict(:key1 => "value1", :key2 => "value2"))

test_eset = ExpressionSet(rand(3, 2),
                          ["S1", "S2"],  # sample_names
                          ["A", "B", "C"],  # feature_names
                          Dict{Symbol,Vector{Any}}(),  # sample_metadata
                          Dict{Symbol,Vector{Any}}(),  # feature_metadata
                          test_miame,  # experiment_data
                          :annotation)

#=
Don't add your tests to runtests.jl. Instead, create files named

    test-title-for-my-test.jl

The file will be automatically included inside a `@testset` with title "Title For My Test".
=#
for (root, dirs, files) in walkdir(@__DIR__)
    for file in files
        if isnothing(match(r"^test-.*\.jl$", file))
            continue
        end
        title = titlecase(replace(splitext(file[6:end])[1], "-" => " "))
        @testset "$title" begin
            include(file)
        end
    end
end
