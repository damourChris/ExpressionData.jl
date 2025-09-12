
import Base.==
import Base.rand

"""
    ExpressionSet

A container for storing gene expression data with associated metadata.

# See also
[`MIAME`](@ref)
[`feature_names`](@ref)
[`sample_names`](@ref)
[`expression_values`](@ref)
[`feature_data`](@ref)
[`phenotype_data`](@ref)
[`experiment_data`](@ref)
[`annotation`](@ref)
"""
struct ExpressionSet
    exprs::Matrix{Union{Missing,Float64}}

    # Name storage
    sample_names::Vector{String}
    feature_names::Vector{String}

    # Additional sample/feature metadata
    sample_metadata::Dict{Symbol,Vector{Any}}
    feature_metadata::Dict{Symbol,Vector{Any}}

    # Lazy-loaded experiment metadata
    experiment_data::Union{MIAME,Nothing}
    annotation::Symbol

    # Cached lookup indices (computed on first access)
    _sample_index::Ref{Union{Dict{String,Int},Nothing}}
    _feature_index::Ref{Union{Dict{String,Int},Nothing}}

    # Inner constructor for controlled creation
    function ExpressionSet(exprs::Matrix{Union{Missing,Float64}},
                           sample_names::Vector{String},
                           feature_names::Vector{String},
                           sample_metadata::Dict{Symbol,Vector{Any}}=Dict{Symbol,
                                                                          Vector{Any}}(),
                           feature_metadata::Dict{Symbol,Vector{Any}}=Dict{Symbol,
                                                                           Vector{Any}}(),
                           experiment_data::Union{MIAME,Nothing}=nothing,
                           annotation::Symbol=:none)

        # Validate dimensions
        n_features, n_samples = size(exprs)
        length(sample_names) == n_samples ||
            throw(DimensionMismatch("sample_names length must match matrix columns"))
        length(feature_names) == n_features ||
            throw(DimensionMismatch("feature_names length must match matrix rows"))

        # Validate metadata dimensions
        for (key, values) in sample_metadata
            length(values) == n_samples ||
                throw(DimensionMismatch("sample_metadata[$key] length must match number of samples"))
        end
        for (key, values) in feature_metadata
            length(values) == n_features ||
                throw(DimensionMismatch("feature_metadata[$key] length must match number of features"))
        end

        # Initialize with lazy caches
        return new(exprs, sample_names, feature_names, sample_metadata, feature_metadata,
                   experiment_data, annotation,
                   Ref{Union{Dict{String,Int},Nothing}}(nothing),
                   Ref{Union{Dict{String,Int},Nothing}}(nothing))
    end
end

# Constructor for other matrix types (converts to Union{Missing,Float64})
function ExpressionSet(exprs::Matrix{<:Real},
                       sample_names::Vector{String},
                       feature_names::Vector{String},
                       sample_metadata::Dict{Symbol,Vector{Any}}=Dict{Symbol,Vector{Any}}(),
                       feature_metadata::Dict{Symbol,Vector{Any}}=Dict{Symbol,Vector{Any}}(),
                       experiment_data::Union{MIAME,Nothing}=nothing,
                       annotation::Symbol=:none)
    # Convert to Union{Missing,Float64} format
    exprs_converted = Matrix{Union{Missing,Float64}}(exprs)
    return ExpressionSet(exprs_converted, sample_names, feature_names,
                         sample_metadata, feature_metadata, experiment_data, annotation)
end

function Base.show(io::IO, eset::ExpressionSet)
    println(io,
            "ExpressionSet with $(size(eset.exprs, 1)) features and $(size(eset.exprs, 2)) samples")
    println(io,
            "Sample metadata keys: $(collect(keys(eset.sample_metadata)))")
    println(io,
            "Feature metadata keys: $(collect(keys(eset.feature_metadata)))")
    println(io, "Has experiment data: $(eset.experiment_data !== nothing)")
    return println(io, "Annotation: $(eset.annotation)")
end

function ==(eset1::ExpressionSet, eset2::ExpressionSet)
    return eset1.exprs == eset2.exprs &&
           eset1.sample_names == eset2.sample_names &&
           eset1.feature_names == eset2.feature_names &&
           eset1.sample_metadata == eset2.sample_metadata &&
           eset1.feature_metadata == eset2.feature_metadata &&
           eset1.experiment_data == eset2.experiment_data &&
           eset1.annotation == eset2.annotation
end

# Cache management for efficient name lookups
"""
    _get_sample_index(eset::ExpressionSet)::Dict{String,Int}

Get or create the sample name to index mapping dictionary.
"""
function _get_sample_index(eset::ExpressionSet)::Dict{String,Int}
    if eset._sample_index[] === nothing
        eset._sample_index[] = Dict{String,Int}(name => i
                                                for (i, name) in
                                                    enumerate(eset.sample_names))
    end
    return eset._sample_index[]
end

"""
    _get_feature_index(eset::ExpressionSet)::Dict{String,Int}

Get or create the feature name to index mapping dictionary.
"""
function _get_feature_index(eset::ExpressionSet)::Dict{String,Int}
    if eset._feature_index[] === nothing
        eset._feature_index[] = Dict{String,Int}(name => i
                                                 for (i, name) in
                                                     enumerate(eset.feature_names))
    end
    return eset._feature_index[]
end

# Fast accessor functions
feature_names(eset::ExpressionSet)::Vector{String} = eset.feature_names
sample_names(eset::ExpressionSet)::Vector{String} = eset.sample_names

"""
    expression_values(eset::ExpressionSet)::DataFrame

Creates a DataFrame with expression values. Optimized to reduce memory allocations.
See also `expression_values(Matrix, eset)` to get direct matrix access.
"""
function expression_values(eset::ExpressionSet)::DataFrame
    # Pre-allocate DataFrame with correct size and column names
    n_features, n_samples = size(eset.exprs)
    col_names = [:feature_names; Symbol.(eset.sample_names)]

    df = DataFrame()
    df[!, :feature_names] = eset.feature_names

    for (i, sample_name) in enumerate(eset.sample_names)
        df[!, Symbol(sample_name)] = @view eset.exprs[:, i]
    end

    return df
end

expression_values(::Type{Matrix}, eset::ExpressionSet)::Matrix{Union{Missing,Float64}} = eset.exprs

function Base.getindex(eset::ExpressionSet, feature_name::String, sample_name::String)
    feature_idx = _get_feature_index(eset)[feature_name]
    sample_idx = _get_sample_index(eset)[sample_name]
    return eset.exprs[feature_idx, sample_idx]
end
function Base.getindex(eset::ExpressionSet, feature_idx::Int, sample_idx::Int)
    return eset.exprs[feature_idx,
                      sample_idx]
end

Base.size(eset::ExpressionSet) = size(eset.exprs)

"""
    feature_data(eset::ExpressionSet)::DataFrame

Creates a DataFrame with feature names and associated metadata.
This is lazily computed and may be slow for large datasets - consider accessing specific metadata directly.
"""
function feature_data(eset::ExpressionSet)::DataFrame
    df = DataFrame(; feature_names=eset.feature_names)

    # Add metadata columns
    for (key, values) in eset.feature_metadata
        df[!, key] = values
    end

    return df
end

"""
    phenotype_data(eset::ExpressionSet)::DataFrame

Creates a DataFrame with sample names and associated metadata.
This is lazily computed and may be slow for large datasets - consider accessing specific metadata directly.
"""
function phenotype_data(eset::ExpressionSet)::DataFrame
    df = DataFrame(; sample_names=eset.sample_names)

    # Add metadata columns
    for (key, values) in eset.sample_metadata
        df[!, key] = values
    end

    return df
end

# Direct metadata access functions (more efficient)
"""
Get sample metadata for a specific key directly (more efficient than phenotype_data()).
"""
function get_sample_metadata(eset::ExpressionSet, key::Symbol)
    return get(eset.sample_metadata, key,
               nothing)
end

"""
Get feature metadata for a specific key directly (more efficient than feature_data()).
"""
function get_feature_metadata(eset::ExpressionSet, key::Symbol)
    return get(eset.feature_metadata, key,
               nothing)
end

"""
    experiment_data(eset::ExpressionSet)::Union{MIAME,Nothing}

Returns the experiment metadata. May be Nothing if no metadata was provided.

# See also
[`MIAME`](@ref)
"""
experiment_data(eset::ExpressionSet)::Union{MIAME,Nothing} = eset.experiment_data

annotation(eset::ExpressionSet)::Symbol = eset.annotation

"""
    has_experiment_data(eset::ExpressionSet)::Bool

Check if experiment data is available without forcing its creation.
"""
has_experiment_data(eset::ExpressionSet)::Bool = eset.experiment_data !== nothing

# Create a function to generate random ExpressionSet
function rand(::Type{ExpressionSet}, n::Int, p::Int)
    exprs = Base.rand(n, p)
    sample_names = ["sample_$i" for i in 1:p]
    feature_names = ["gene_$i" for i in 1:n]

    # Optional: add some sample metadata for testing
    sample_metadata = Dict{Symbol,Vector{Any}}()

    # Optional: add some feature metadata for testing
    feature_metadata = Dict{Symbol,Vector{Any}}()

    # Create minimal MIAME data for testing
    experiment_data = MIAME(;
                            name="Random",
                            lab="Test Lab",
                            contact="Test Contact",
                            title="Random Expression Set",
                            abstract="Randomly generated data for testing",
                            url="",
                            samples=sample_names,
                            hybridizations=String[],
                            norm_controls=String[],
                            preprocessing=String[],
                            pub_med_id="",
                            other=Dict{Symbol,String}())

    return ExpressionSet(exprs, sample_names, feature_names, sample_metadata,
                         feature_metadata, experiment_data, :Random)
end

"""
    _resolve_indices_optimized(names_or_indices, eset::ExpressionSet, is_samples::Bool)

Optimized name resolution using cached dictionaries for O(1) lookups.
"""
function _resolve_indices_optimized(names_or_indices, eset::ExpressionSet, is_samples::Bool)
    if names_or_indices isa AbstractVector{<:AbstractString}
        # Use cached lookup dictionaries for O(1) performance
        lookup_dict = is_samples ? _get_sample_index(eset) : _get_feature_index(eset)
        collection_name = is_samples ? "Sample" : "Feature"

        indices = Vector{Int}(undef, length(names_or_indices))
        for (i, name) in enumerate(names_or_indices)
            idx = get(lookup_dict, name, nothing)
            if idx === nothing
                error("$(collection_name) name '$name' not found in ExpressionSet")
            end
            indices[i] = idx
        end
        return indices
    else
        # Indices already provided - validate bounds
        indices = collect(names_or_indices)
        max_idx = is_samples ? length(eset.sample_names) : length(eset.feature_names)
        collection_name = is_samples ? "sample" : "feature"

        @boundscheck for idx in indices
            if idx < 1 || idx > max_idx
                error("$(collection_name) index $idx out of bounds (1:$max_idx)")
            end
        end
        return indices
    end
end

"""
    subset(eset::ExpressionSet; samples=nothing, features=nothing)

Create a subset of an ExpressionSet by selecting specific samples and/or features.
Optimized for performance using cached lookups and efficient array operations.

# Arguments
- `samples`: Vector of sample names or indices to include
- `features`: Vector of feature names or indices to include

# Examples
```julia
# Subset by sample names
subset_eset = subset(eset; samples=["sample_1", "sample_2"])

# Subset by feature indices
subset_eset = subset(eset; features=1:100)

# Subset both
subset_eset = subset(eset; samples=1:5, features=["gene1", "gene2"])
```
"""
function subset(eset::ExpressionSet; samples=nothing, features=nothing)
    # Handle sample subsetting
    if samples !== nothing
        sample_indices = _resolve_indices_optimized(samples, eset, true)
        new_exprs = eset.exprs[:, sample_indices]
        new_sample_names = eset.sample_names[sample_indices]

        # Subset sample metadata efficiently
        new_sample_metadata = Dict{Symbol,Vector{Any}}()
        for (key, values) in eset.sample_metadata
            new_sample_metadata[key] = values[sample_indices]
        end

        # Update experiment data samples if available
        new_experiment_samples = eset.experiment_data !== nothing ?
                                 eset.experiment_data.samples[sample_indices] : String[]
    else
        new_exprs = eset.exprs
        new_sample_names = eset.sample_names
        new_sample_metadata = eset.sample_metadata
        new_experiment_samples = eset.experiment_data !== nothing ?
                                 eset.experiment_data.samples : String[]
    end

    # Handle feature subsetting
    if features !== nothing
        feature_indices = _resolve_indices_optimized(features, eset, false)
        new_exprs = new_exprs[feature_indices, :]
        new_feature_names = eset.feature_names[feature_indices]

        # Subset feature metadata efficiently
        new_feature_metadata = Dict{Symbol,Vector{Any}}()
        for (key, values) in eset.feature_metadata
            new_feature_metadata[key] = values[feature_indices]
        end
    else
        new_feature_names = eset.feature_names
        new_feature_metadata = eset.feature_metadata
    end

    # Create new MIAME with updated sample list (only if original had MIAME data)
    new_experiment_data = if eset.experiment_data !== nothing
        MIAME(;
              name=eset.experiment_data.name,
              lab=eset.experiment_data.lab,
              contact=eset.experiment_data.contact,
              title=eset.experiment_data.title,
              abstract=eset.experiment_data.abstract,
              url=eset.experiment_data.url,
              pub_med_id=eset.experiment_data.pub_med_id,
              samples=new_experiment_samples,
              hybridizations=eset.experiment_data.hybridizations,
              norm_controls=eset.experiment_data.norm_controls,
              preprocessing=eset.experiment_data.preprocessing,
              other=eset.experiment_data.other)
    else
        nothing
    end

    return ExpressionSet(new_exprs, new_sample_names, new_feature_names,
                         new_sample_metadata, new_feature_metadata,
                         new_experiment_data, eset.annotation)
end

"""
    combine(esets::Vector{ExpressionSet})

Combine multiple ExpressionSets into a single ExpressionSet.
All ExpressionSets must have the same features.
"""
function combine(esets::Vector{ExpressionSet})
    if length(esets) == 0
        error("Cannot combine empty vector of ExpressionSets")
    end

    if length(esets) == 1
        return esets[1]
    end

    # Check that all have same features
    first_features = esets[1].feature_names
    for eset in esets[2:end]
        if eset.feature_names != first_features
            error("All ExpressionSets must have the same features to combine")
        end
    end

    # Combine expression data efficiently
    combined_exprs = hcat([eset.exprs for eset in esets]...)

    # Combine sample names
    combined_sample_names = String[]
    for eset in esets
        append!(combined_sample_names, eset.sample_names)
    end

    # Use feature names from first ExpressionSet
    combined_feature_names = esets[1].feature_names

    # Combine sample metadata (union of all keys)
    combined_sample_metadata = Dict{Symbol,Vector{Any}}()
    all_sample_keys = Set{Symbol}()
    for eset in esets
        union!(all_sample_keys, keys(eset.sample_metadata))
    end

    for key in all_sample_keys
        combined_values = Vector{Any}()
        for eset in esets
            if haskey(eset.sample_metadata, key)
                append!(combined_values, eset.sample_metadata[key])
            else
                # Fill missing values with nothing
                append!(combined_values, fill(nothing, length(eset.sample_names)))
            end
        end
        combined_sample_metadata[key] = combined_values
    end

    # Use feature metadata from first ExpressionSet
    combined_feature_metadata = esets[1].feature_metadata

    # Combine experiment data if available
    combined_experiment_data = if all(eset -> eset.experiment_data !== nothing, esets)
        # Combine samples list
        all_samples = String[]
        for eset in esets
            append!(all_samples, eset.experiment_data.samples)
        end

        # Use first experiment data as template with combined samples
        first_exp = esets[1].experiment_data
        MIAME(;
              name=first_exp.name,
              lab=first_exp.lab,
              contact=first_exp.contact,
              title="Combined: " * first_exp.title,
              abstract=first_exp.abstract,
              url=first_exp.url,
              pub_med_id=first_exp.pub_med_id,
              samples=all_samples,
              hybridizations=first_exp.hybridizations,
              norm_controls=first_exp.norm_controls,
              preprocessing=first_exp.preprocessing,
              other=first_exp.other)
    else
        nothing
    end

    # Use annotation from first ExpressionSet
    combined_annotation = esets[1].annotation

    return ExpressionSet(combined_exprs, combined_sample_names, combined_feature_names,
                         combined_sample_metadata, combined_feature_metadata,
                         combined_experiment_data, combined_annotation)
end
