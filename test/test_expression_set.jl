
# Test feature_names function
@testset "feature_names() should return the feature names" begin
    expected = ["A", "B", "C"]

    actual = feature_names(test_eset)

    @test actual == expected
end

# Test sample_names function
@testset "sample_names() should return the sample names" begin
    expected = ["S1", "S2"]

    actual = sample_names(test_eset)

    @test actual == expected
end

# Test expression_values function
@testset "expression_values() should return the expression values - DataFrames" begin
    expected = DataFrame(;
                         feature_names=["A", "B", "C"],
                         S1=[test_eset.exprs[1, 1], test_eset.exprs[2, 1],
                             test_eset.exprs[3, 1]],
                         S2=[test_eset.exprs[1, 2], test_eset.exprs[2, 2],
                             test_eset.exprs[3, 2]])

    actual = expression_values(test_eset)

    @test actual == expected
end
@testset "expression_values() should return the expression values - Matrix" begin
    expected = test_eset.exprs

    actual = expression_values(Matrix, test_eset)

    @test actual == expected
end

# Test feature_data function
@testset "feature_data() should return the feature data" begin
    expected = DataFrame(; feature_names=["A", "B", "C"])

    actual = feature_data(test_eset)

    @test actual == expected
end

# Test phenotype_data function
@testset "phenotype_data() should return the phenotype data" begin
    expected = DataFrame(; sample_names=["S1", "S2"])

    actual = phenotype_data(test_eset)

    @test actual == expected
end

# Test get_annotation function
@testset "get_annotation() should return the annotation value" begin
    expected = :annotation

    actual = annotation(test_eset)

    @test actual == expected
end

# Test rcopy function
@testset "convert a R ExpressionSet into Julia" begin
    R"""
    eset <- readRDS($test_r_eset_path)[[1]]
    """
    eset_R = @rget eset

    actual = convert(ExpressionSet, eset_R)

    @test typeof(actual) == ExpressionSet
end
