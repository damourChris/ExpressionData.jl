"""
    _prepare_matrix_for_hdf5(matrix::Matrix{Union{Missing,Float64}})

Internal function to convert Union{Missing,Float64} matrix to Float64 matrix
suitable for HDF5 storage. Missing values are converted to NaN.
"""
function _prepare_matrix_for_hdf5(matrix::Matrix{Union{Missing,Float64}})
    result = Matrix{Float64}(undef, size(matrix))
    for i in eachindex(matrix)
        result[i] = ismissing(matrix[i]) ? NaN : Float64(matrix[i])
    end
    return result
end

"""
    _restore_matrix_from_hdf5(matrix::Matrix{Float64}, has_missing::Bool)

Internal function to convert Float64 matrix back to Union{Missing,Float64} matrix,
restoring missing values from NaN if the original had missing values.
"""
function _restore_matrix_from_hdf5(matrix::Matrix{Float64}, has_missing::Bool)
    if !has_missing
        return matrix
    end

    result = Matrix{Union{Missing,Float64}}(undef, size(matrix))
    for i in eachindex(matrix)
        result[i] = isnan(matrix[i]) ? missing : matrix[i]
    end
    return result
end

"""
    save_eset(eset::ExpressionSet, file::AbstractString)

Saves an `ExpressionSet` object to a file. Supports multiple Julia-native formats:
- `.jld2`: JLD2 format (recommended for performance and cross-session compatibility)
- `.jls` or `.dat`: Julia serialization format

To load the object back, use `load_eset`.

# See also
[`load_eset`](@ref)
"""
function save_eset(eset::ExpressionSet, file::AbstractString)
    if endswith(file, ".jld2")
        return save_eset_jld2(eset, file)
    elseif endswith(file, ".h5") || endswith(file, ".hdf5")
        return save_eset_hdf5(eset, file)
    elseif endswith(file, ".arrow")
        return save_eset_arrow(eset, file)
    elseif endswith(file, ".jls") || endswith(file, ".dat")
        return serialize(file, eset)
    else
        # Default to JLD2 format
        return save_eset_jld2(eset, file * ".jld2")
    end
end

"""
    save_eset_jld2(eset::ExpressionSet, file::AbstractString)

Save an `ExpressionSet` object to a JLD2 file.
"""
function save_eset_jld2(eset::ExpressionSet, file::AbstractString)
    return save(file,
                "exprs", eset.exprs,
                "sample_names", eset.sample_names,
                "feature_names", eset.feature_names,
                "sample_metadata", eset.sample_metadata,
                "feature_metadata", eset.feature_metadata,
                "experiment_data", eset.experiment_data,
                "annotation", eset.annotation)
end

"""
    save_eset_hdf5(eset::ExpressionSet, file::AbstractString)

Save an `ExpressionSet` object to an HDF5 file.

Note: This function handles Union{Missing,Float64} types by converting them to
a format compatible with HDF5 (using NaN for missing values).
"""
function save_eset_hdf5(eset::ExpressionSet, file::AbstractString)
    h5open(file, "w") do fid
        # Handle Union{Missing,Float64} types by converting to Float64 with NaN for missing
        exprs_for_hdf5 = _prepare_matrix_for_hdf5(eset.exprs)
        fid["exprs"] = exprs_for_hdf5

        # Store information about missing values
        has_missing = any(ismissing, eset.exprs)
        fid["has_missing_values"] = has_missing

        # Save names directly
        fid["sample_names"] = eset.sample_names
        fid["feature_names"] = eset.feature_names

        # Save sample metadata
        grp_sample_meta = create_group(fid, "sample_metadata")
        for (key, values) in eset.sample_metadata
            grp_sample_meta[string(key)] = values
        end

        # Save feature metadata
        grp_feature_meta = create_group(fid, "feature_metadata")
        for (key, values) in eset.feature_metadata
            grp_feature_meta[string(key)] = values
        end

        # Save MIAME data (if available)
        if eset.experiment_data !== nothing
            grp_miame = create_group(fid, "experiment_data")
            grp_miame["name"] = eset.experiment_data.name
            grp_miame["lab"] = eset.experiment_data.lab
            grp_miame["contact"] = eset.experiment_data.contact
            grp_miame["title"] = eset.experiment_data.title
            grp_miame["abstract"] = eset.experiment_data.abstract
            grp_miame["url"] = eset.experiment_data.url
            grp_miame["pub_med_id"] = eset.experiment_data.pub_med_id
            grp_miame["samples"] = eset.experiment_data.samples
            grp_miame["hybridizations"] = eset.experiment_data.hybridizations
            grp_miame["norm_controls"] = eset.experiment_data.norm_controls
            grp_miame["preprocessing"] = eset.experiment_data.preprocessing

            # Save other metadata as key-value pairs
            grp_other = create_group(grp_miame, "other")
            for (key, value) in eset.experiment_data.other
                grp_other[string(key)] = value
            end
        end

        # Save annotation
        return fid["annotation"] = string(eset.annotation)
    end
end

"""
    save_eset_arrow(eset::ExpressionSet, file::AbstractString)

Save an `ExpressionSet` object to an Arrow file.
Note: This saves the data in a flattened format optimized for analytical workloads.
"""
function save_eset_arrow(eset::ExpressionSet, file::AbstractString)
    # Create a flattened representation for Arrow format
    expr_df = expression_values(eset)

    # Add feature names as a column (since row names aren't preserved in Arrow)
    expr_df[!, :feature_names] = feature_names(eset)

    # Add metadata columns (handle case where experiment_data might be nothing)
    if eset.experiment_data !== nothing
        expr_df[!, :lab] .= eset.experiment_data.lab
        expr_df[!, :contact] .= eset.experiment_data.contact
        expr_df[!, :title] .= eset.experiment_data.title
    else
        expr_df[!, :lab] .= ""
        expr_df[!, :contact] .= ""
        expr_df[!, :title] .= ""
    end
    expr_df[!, :annotation] .= string(eset.annotation)

    return Arrow.write(file, expr_df)
end

"""
    load_eset(file::AbstractString)::ExpressionSet

Loads an `ExpressionSet` object from a file. The file should be in a serialized format.
To save an object, use `save_eset`.

# See also
[`save_eset`](@ref)
"""
function load_eset(file::AbstractString)::ExpressionSet
    # Support multiple Julia-native formats
    if endswith(file, ".jld2")
        return load_eset_jld2(file)
    elseif endswith(file, ".h5") || endswith(file, ".hdf5")
        return load_eset_hdf5(file)
    elseif endswith(file, ".arrow")
        return load_eset_arrow(file)
    elseif endswith(file, ".jls") || endswith(file, ".dat")
        # Julia serialization format - deserialize the entire ExpressionSet object
        return deserialize(file)
    else
        error("Unsupported file format. Supported formats: .jld2, .h5/.hdf5, .arrow, .jls, .dat")
    end
end

"""
    load_eset_jld2(file::AbstractString)::ExpressionSet

Load an `ExpressionSet` object from a JLD2 file.
"""
function load_eset_jld2(file::AbstractString)::ExpressionSet
    data = load(file)

    # Handle both old and new format for backward compatibility
    if haskey(data, "sample_names")
        # New optimized format
        return ExpressionSet(data["exprs"],
                             data["sample_names"],
                             data["feature_names"],
                             get(data, "sample_metadata", Dict{Symbol,Vector{Any}}()),
                             get(data, "feature_metadata", Dict{Symbol,Vector{Any}}()),
                             data["experiment_data"],
                             data["annotation"])
    else
        # Old format - convert to new format
        return ExpressionSet(data["exprs"],
                             data["phenotype_data"],
                             data["feature_data"],
                             data["experiment_data"],
                             data["annotation"])
    end
end

"""
    load_eset_hdf5(file::AbstractString)::ExpressionSet

Load an `ExpressionSet` object from an HDF5 file.
"""
function load_eset_hdf5(file::AbstractString)::ExpressionSet
    h5open(file, "r") do fid
        # Load expression matrix and restore missing values if needed
        exprs_raw = read(fid["exprs"])
        has_missing = haskey(fid, "has_missing_values") ? read(fid["has_missing_values"]) :
                      false
        exprs = _restore_matrix_from_hdf5(exprs_raw, has_missing)

        # Check for new format vs old format
        if haskey(fid, "sample_names")
            # New optimized format
            sample_names = read(fid["sample_names"])
            feature_names = read(fid["feature_names"])

            # Load sample metadata
            sample_metadata = Dict{Symbol,Vector{Any}}()
            if haskey(fid, "sample_metadata")
                meta_grp = fid["sample_metadata"]
                for name in keys(meta_grp)
                    sample_metadata[Symbol(name)] = read(meta_grp[name])
                end
            end

            # Load feature metadata
            feature_metadata = Dict{Symbol,Vector{Any}}()
            if haskey(fid, "feature_metadata")
                meta_grp = fid["feature_metadata"]
                for name in keys(meta_grp)
                    feature_metadata[Symbol(name)] = read(meta_grp[name])
                end
            end

            # Load MIAME data (if available)
            experiment_data = if haskey(fid, "experiment_data")
                miame_grp = fid["experiment_data"]
                other_grp = miame_grp["other"]
                other_dict = Dict{Symbol,String}()
                for name in keys(other_grp)
                    other_dict[Symbol(name)] = read(other_grp[name])
                end

                MIAME(;
                      name=read(miame_grp["name"]),
                      lab=read(miame_grp["lab"]),
                      contact=read(miame_grp["contact"]),
                      title=read(miame_grp["title"]),
                      abstract=read(miame_grp["abstract"]),
                      url=read(miame_grp["url"]),
                      pub_med_id=read(miame_grp["pub_med_id"]),
                      samples=read(miame_grp["samples"]),
                      hybridizations=read(miame_grp["hybridizations"]),
                      norm_controls=read(miame_grp["norm_controls"]),
                      preprocessing=read(miame_grp["preprocessing"]),
                      other=other_dict)
            else
                nothing
            end

            # Load annotation
            annotation = Symbol(read(fid["annotation"]))

            return ExpressionSet(exprs, sample_names, feature_names,
                                 sample_metadata, feature_metadata,
                                 experiment_data, annotation)
        else
            # Old format - convert to new format
            # Load phenotype data
            pheno_grp = fid["phenotype_data"]
            pheno_data = DataFrame()
            for name in keys(pheno_grp)
                pheno_data[!, Symbol(name)] = read(pheno_grp[name])
            end

            # Load feature data
            feat_grp = fid["feature_data"]
            feature_data = DataFrame()
            for name in keys(feat_grp)
                feature_data[!, Symbol(name)] = read(feat_grp[name])
            end

            # Load MIAME data
            miame_grp = fid["experiment_data"]
            other_grp = miame_grp["other"]
            other_dict = Dict{Symbol,String}()
            for name in keys(other_grp)
                other_dict[Symbol(name)] = read(other_grp[name])
            end

            experiment_data = MIAME(;
                                    name=read(miame_grp["name"]),
                                    lab=read(miame_grp["lab"]),
                                    contact=read(miame_grp["contact"]),
                                    title=read(miame_grp["title"]),
                                    abstract=read(miame_grp["abstract"]),
                                    url=read(miame_grp["url"]),
                                    pub_med_id=read(miame_grp["pub_med_id"]),
                                    samples=read(miame_grp["samples"]),
                                    hybridizations=read(miame_grp["hybridizations"]),
                                    norm_controls=read(miame_grp["norm_controls"]),
                                    preprocessing=read(miame_grp["preprocessing"]),
                                    other=other_dict)

            # Load annotation
            annotation = Symbol(read(fid["annotation"]))

            return ExpressionSet(exprs, pheno_data, feature_data, experiment_data,
                                 annotation)
        end
    end
end

"""
    load_eset_arrow(file::AbstractString)::ExpressionSet

Load an `ExpressionSet` object from an Arrow file.
Note: This reconstructs the ExpressionSet from the flattened Arrow format.
"""
function load_eset_arrow(file::AbstractString)::ExpressionSet
    df = DataFrame(Arrow.Table(file))

    # Extract metadata columns
    lab = df[1, :lab]
    contact = df[1, :contact]
    title = df[1, :title]
    annotation = Symbol(df[1, :annotation])

    # Extract feature names and convert to Vector{String}
    feature_names_vec = Vector{String}(df[!, :feature_names])

    # Remove metadata columns to get expression data
    select!(df, Not([:lab, :contact, :title, :annotation, :feature_names]))
    sample_names = Vector{String}(names(df))

    # Convert to matrix
    exprs = Matrix(df)

    # Create empty metadata dictionaries
    sample_metadata = Dict{Symbol,Vector{Any}}()
    feature_metadata = Dict{Symbol,Vector{Any}}()

    # Create minimal MIAME object
    experiment_data = MIAME(;
                            name="",
                            lab=lab,
                            contact=contact,
                            title=title,
                            abstract="",
                            url="",
                            pub_med_id="",
                            samples=sample_names,
                            hybridizations=String[],
                            norm_controls=String[],
                            preprocessing=String[],
                            other=Dict{Symbol,String}())

    return ExpressionSet(exprs, sample_names, feature_names_vec, sample_metadata,
                         feature_metadata, experiment_data, annotation)
end
