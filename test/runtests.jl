using ExpressionData
using RCall
using DataFrames
using Serialization
using Test

const test_r_eset_file = "GSE1_series_matrix.rds"
const test_r_eset_path = joinpath(@__DIR__, "data", test_r_eset_file)

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
test_eset = ExpressionSet(rand(3, 2), DataFrame(; sample_names=["S1", "S2"]),
                          DataFrame(; feature_names=["A", "B", "C"]),
                          test_miame,
                          :annotation)

@testset "ExpressionData.jl" begin
    include("./test_expression_set.jl")
    include("./test_miame.jl")
    include("./test_io.jl")
end
