@testset "Test serializing and deserializing an ExpressionSet" begin
    # Serialize the ExpressionSet
    path = tempname()
    serialize(path, test_eset)

    # Deserialize the ExpressionSet
    actual = deserialize(path)

    @test actual == test_eset
end