
# Test abstract function
@testset "abstract function" begin
    @test abstract(test_miame) == "Abstract"
end

# Test info function
@testset "info function" begin
    expected = (; name="Name", lab="Lab", contact="Contact", title="Title", url="URL")
    @test info(test_miame) == expected
end

# Test hybridizations function
@testset "hybridizations function" begin
    @test hybridizations(test_miame) == ["Hybridization1", "Hybridization2"]
end

# Test norm_controls function
@testset "norm_controls function" begin
    @test norm_controls(test_miame) == ["Control1", "Control2"]
end

# Test other function
@testset "other function" begin
    @test other(test_miame) == Dict(:key1 => "value1", :key2 => "value2")
end

# Test notes function
@testset "notes function" begin
    @test notes(test_miame) == Dict(:key1 => "value1", :key2 => "value2")
end

# Test preprocessing function
@testset "preprocessing function" begin
    @test preprocessing(test_miame) == ["Preprocessing1", "Preprocessing2"]
end

# Test pub_med_ids function
@testset "pub_med_id function" begin
    @test pub_med_id(test_miame) == "ID1"
end

# Test addition of MIAME structs
@testset "Merge of MIAME structs" begin
    miame1 = MIAME(;
                   name="Name1",
                   lab="Lab1",
                   contact="Contact1",
                   title="Title1",
                   abstract="Abstract1",
                   url="URL1",
                   samples=["Sample1"],
                   hybridizations=["Hybridization1"],
                   norm_controls=["Control1"],
                   preprocessing=["Preprocessing1"],
                   pub_med_id="ID1",
                   other=Dict(:key1 => "value1"))
    miame2 = MIAME(;
                   name="Name2",
                   lab="Lab2",
                   contact="Contact2",
                   title="Title2",
                   abstract="Abstract2",
                   url="URL2",
                   samples=["Sample2"],
                   hybridizations=["Hybridization2"],
                   norm_controls=["Control2"],
                   preprocessing=["Preprocessing2"],
                   pub_med_id="ID2",
                   other=Dict(:key2 => "value2"))

    expected = MIAME(;
                     name="Name1Name2",
                     lab="Lab1Lab2",
                     contact="Contact1Contact2",
                     title="Title1Title2",
                     abstract="Abstract1Abstract2",
                     url="URL1URL2",
                     samples=["Sample1", "Sample2"],
                     hybridizations=["Hybridization1", "Hybridization2"],
                     norm_controls=["Control1", "Control2"],
                     preprocessing=["Preprocessing1", "Preprocessing2"],
                     pub_med_id="ID1ID2",
                     other=Dict(:key1 => "value1", :key2 => "value2"))

    @test_broken merge(miame1, miame2) == expected
end

# Test rcopy function
@testset "rcopy function" begin
    R"""
    eset <- readRDS($test_r_eset_path)
    edata <- eset[[1]]@experimentData
    """
    edata_R = @rget edata

    miame = rcopy(MIAME, edata_R)

    @test miame.name == "Michael,,Bittner"
    @test miame.lab == ""
    @test miame.contact == "mbittner@nhgri.nih.gov"
    @test miame.title == "NHGRI_Melanoma_class"
    @test miame.abstract ==
          "This series represents a group of cutaneous malignant melanomas and unrelated controls which were clustered based on correlation coefficients calculated through a comparison of gene expression\nprofiles.\nKeywords: other"
    @test miame.url == "https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE1"
    @test miame.samples == []
    @test miame.hybridizations == []
    @test miame.norm_controls == []
    @test miame.preprocessing == []
    @test miame.pub_med_id == "10952317"
    # TODO: Test other field
end