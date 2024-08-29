@testset "Test serializing and deserializing an ExpressionSet" begin
    # Serialize the ExpressionSet
    path = tempname()
    serialize(path, test_eset)

    # Deserialize the ExpressionSet
    actual = deserialize(path)

    @test actual == test_eset
end

@testset "Loading from RDS files" begin
    # Load the RDS file
    actual = load_eset(test_r_eset_path)

    @test typeof(actual) == typeof(test_eset)
end