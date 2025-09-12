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
    data = Dict("exprs" => eset.exprs,
                "feature_data" => eset.feature_data,
                "phenotype_data" => eset.phenotype_data,
                "experiment_data" => eset.experiment_data,
                "annotation" => eset.annotation)

    if endswith(file, ".jld2")
        return save_eset_jld2(eset, file)
    elseif endswith(file, ".h5") || endswith(file, ".hdf5")
        return save_eset_hdf5(eset, file)
    elseif endswith(file, ".arrow")
        return save_eset_arrow(eset, file)
    elseif endswith(file, ".jls") || endswith(file, ".dat")
        return serialize(file, data)
    else
        # Default to JLD2 format
        return save_eset_jld2(eset, file * ".jld2")
    end
end

"""
    save_eset_jld2(eset::ExpressionSet, file::AbstractString)

Save an `ExpressionSet` object to a JLD2 file. JLD2 provides better performance
and cross-session compatibility compared to Julia serialization.
"""
function save_eset_jld2(eset::ExpressionSet, file::AbstractString)
    return save(file,
                "exprs", eset.exprs,
                "feature_data", eset.feature_data,
                "phenotype_data", eset.phenotype_data,
                "experiment_data", eset.experiment_data,
                "annotation", eset.annotation)
end

"""
    save_eset_hdf5(eset::ExpressionSet, file::AbstractString)

Save an `ExpressionSet` object to an HDF5 file. HDF5 provides excellent compression
and is widely supported across different platforms and languages.
"""
function save_eset_hdf5(eset::ExpressionSet, file::AbstractString)
    h5open(file, "w") do fid
        # Save expression matrix
        fid["exprs"] = eset.exprs

        # Save DataFrames as separate datasets
        grp_phenotype = create_group(fid, "phenotype_data")
        for (i, col) in enumerate(names(eset.phenotype_data))
            grp_phenotype[col] = eset.phenotype_data[!, col]
        end

        grp_feature = create_group(fid, "feature_data")
        for (i, col) in enumerate(names(eset.feature_data))
            grp_feature[col] = eset.feature_data[!, col]
        end

        # Save MIAME data
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

        # Save annotation
        return fid["annotation"] = string(eset.annotation)
    end
end

"""
    save_eset_arrow(eset::ExpressionSet, file::AbstractString)

Save an `ExpressionSet` object to an Arrow file. Note: This saves the data in a
flattened format optimized for analytical workloads.
"""
function save_eset_arrow(eset::ExpressionSet, file::AbstractString)
    # Create a flattened representation for Arrow format
    expr_df = expression_values(eset)

    # Add metadata columns
    expr_df[!, :lab] .= eset.experiment_data.lab
    expr_df[!, :contact] .= eset.experiment_data.contact
    expr_df[!, :title] .= eset.experiment_data.title
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
        # Julia serialization format
        data = deserialize(file)
        return ExpressionSet(data["exprs"],
                             data["phenotype_data"],
                             data["feature_data"],
                             data["experiment_data"],
                             data["annotation"])
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
    return ExpressionSet(data["exprs"],
                         data["phenotype_data"],
                         data["feature_data"],
                         data["experiment_data"],
                         data["annotation"])
end

"""
    load_eset_hdf5(file::AbstractString)::ExpressionSet

Load an `ExpressionSet` object from an HDF5 file.
"""
function load_eset_hdf5(file::AbstractString)::ExpressionSet
    h5open(file, "r") do fid
        # Load expression matrix
        exprs = read(fid["exprs"])

        # Load phenotype data
        pheno_grp = fid["phenotype_data"]
        pheno_data = DataFrame()
        for name in names(pheno_grp)
            pheno_data[!, Symbol(name)] = read(pheno_grp[name])
        end

        # Load feature data
        feat_grp = fid["feature_data"]
        feature_data = DataFrame()
        for name in names(feat_grp)
            feature_data[!, Symbol(name)] = read(feat_grp[name])
        end

        # Load MIAME data
        miame_grp = fid["experiment_data"]
        other_grp = miame_grp["other"]
        other_dict = Dict{Symbol,String}()
        for name in names(other_grp)
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

        return ExpressionSet(exprs, pheno_data, feature_data, experiment_data, annotation)
    end
end

"""
    load_eset_arrow(file::AbstractString)::ExpressionSet

Load an `ExpressionSet` object from an Arrow file. Note: This reconstructs the
ExpressionSet from the flattened Arrow format.
"""
function load_eset_arrow(file::AbstractString)::ExpressionSet
    df = DataFrame(Arrow.Table(file))

    # Extract metadata columns
    lab = df[1, :lab]
    contact = df[1, :contact]
    title = df[1, :title]
    annotation = Symbol(df[1, :annotation])

    # Remove metadata columns to get expression data
    select!(df, Not([:lab, :contact, :title, :annotation]))

    # Separate feature names from expression values
    feature_names = df[!, :feature_names]
    select!(df, Not(:feature_names))
    sample_names = names(df)

    # Convert to matrix
    exprs = Matrix(df)

    # Create DataFrames
    phenotype_data = DataFrame(; sample_names=sample_names)
    feature_data = DataFrame(; feature_names=feature_names)

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

    return ExpressionSet(exprs, phenotype_data, feature_data, experiment_data, annotation)
end
