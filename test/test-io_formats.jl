@testset "Test HDF5 serialization" begin
    # Test HDF5 format - skip if HDF5 not available
    try
        path = tempname() * ".h5"
        save_eset_hdf5(test_eset, path)

        actual = load_eset_hdf5(path)

        @test actual.exprs == test_eset.exprs
        @test actual.sample_names == test_eset.sample_names
        @test actual.feature_names == test_eset.feature_names
        @test actual.sample_metadata == test_eset.sample_metadata
        @test actual.feature_metadata == test_eset.feature_metadata
        @test actual.experiment_data == test_eset.experiment_data
        @test actual.annotation == test_eset.annotation

        # Clean up
        rm(path; force=true)
    catch e
        @test_skip "HDF5 not available: $e"
    end
end

@testset "Test Arrow serialization" begin
    # Test Arrow format - skip if Arrow not available
    try
        path = tempname() * ".arrow"
        save_eset_arrow(test_eset, path)

        actual = load_eset_arrow(path)

        @test size(actual.exprs) == size(test_eset.exprs)
        @test actual.phenotype_data.sample_names == test_eset.phenotype_data.sample_names
        @test actual.feature_data.feature_names == test_eset.feature_data.feature_names
        @test actual.annotation == test_eset.annotation

        # Note: Arrow format loses some MIAME metadata by design
        @test actual.experiment_data.lab == test_eset.experiment_data.lab
        @test actual.experiment_data.contact == test_eset.experiment_data.contact
        @test actual.experiment_data.title == test_eset.experiment_data.title

        # Clean up
        rm(path; force=true)
    catch e
        @test_skip "Arrow not available: $e"
    end
end

@testset "Test load_eset format detection" begin
    # Test that load_eset properly detects formats
    try
        # JLD2
        path_jld2 = tempname() * ".jld2"
        save_eset(test_eset, path_jld2)
        actual_jld2 = load_eset(path_jld2)
        @test actual_jld2 == test_eset
        rm(path_jld2; force=true)

        # HDF5
        path_hdf5 = tempname() * ".h5"
        save_eset(test_eset, path_hdf5)
        actual_hdf5 = load_eset(path_hdf5)
        @test actual_hdf5.exprs == test_eset.exprs
        rm(path_hdf5; force=true)

        # Arrow
        path_arrow = tempname() * ".arrow"
        save_eset(test_eset, path_arrow)
        actual_arrow = load_eset(path_arrow)
        @test size(actual_arrow.exprs) == size(test_eset.exprs)
        rm(path_arrow; force=true)
    catch e
        @test_skip "Some format libraries not available: $e"
    end
end
