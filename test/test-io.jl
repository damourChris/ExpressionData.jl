@testset "Test serializing and deserializing an ExpressionSet" begin
    # Serialize the ExpressionSet
    path = tempname()
    serialize(path, test_eset)

    # Deserialize the ExpressionSet
    actual = deserialize(path)

    @test actual == test_eset
end

# Note: RDS loading tests moved to ExpressionDataInterop.jl

@testset "Test JLD2 serialization" begin
    # Test JLD2 format
    path = tempname() * ".jld2"
    save_eset_jld2(test_eset, path)

    actual = load_eset_jld2(path)

    @test actual == test_eset

    # Clean up
    rm(path; force=true)
end
