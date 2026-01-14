
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

# Note: R conversion tests moved to ExpressionDataInterop.jl

@testset "generate a random ExpressionSet" begin
    actual = rand(ExpressionSet, 3, 2)

    @test typeof(actual) == ExpressionSet
    @test size(expression_values(actual)) == (3, 3)  # 3 features, 3 columns (feature_names + 2 samples)
    @test length(sample_names(actual)) == 2  # 2 samples
    @test length(feature_names(actual)) == 3  # 3 features
end

@testset "subset ExpressionSet by samples" begin
    # Test subsetting by sample names
    subset_eset = ExpressionData.subset(test_eset; samples=["S1"])

    @test size(subset_eset.exprs) == (3, 1)
    @test sample_names(subset_eset) == ["S1"]
    @test feature_names(subset_eset) == ["A", "B", "C"]
end

@testset "subset ExpressionSet by features" begin
    # Test subsetting by feature names
    subset_eset = ExpressionData.subset(test_eset; features=["A", "B"])

    @test size(subset_eset.exprs) == (2, 2)
    @test sample_names(subset_eset) == ["S1", "S2"]
    @test feature_names(subset_eset) == ["A", "B"]
end

@testset "combine ExpressionSets" begin
    # Create two compatible ExpressionSets
    eset1 = ExpressionSet(rand(3, 2),
                          ["S1", "S2"],
                          ["A", "B", "C"],
                          Dict{Symbol,Vector{Any}}(),
                          Dict{Symbol,Vector{Any}}(),
                          test_miame,
                          :test1)

    eset2 = ExpressionSet(rand(3, 2),
                          ["S3", "S4"],
                          ["A", "B", "C"],
                          Dict{Symbol,Vector{Any}}(),
                          Dict{Symbol,Vector{Any}}(),
                          test_miame,
                          :test2)

    combined = ExpressionData.combine([eset1, eset2])

    @test size(combined.exprs) == (3, 4)
    @test length(sample_names(combined)) == 4
    @test sample_names(combined) == ["S1", "S2", "S3", "S4"]
    @test feature_names(combined) == ["A", "B", "C"]
end
