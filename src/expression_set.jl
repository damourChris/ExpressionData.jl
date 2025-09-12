
import Base.==
import Base.rand

"""
    ExpressionSet

An `ExpressionSet` object is a container for storing gene expression data, along with associated metadata.
It follows the `ExpressionSet` class from the R package from Bioconductor: `Biobase`.

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
    phenotype_data::DataFrame
    feature_data::DataFrame
    experiment_data::MIAME
    annotation::Symbol
end

function Base.show(io::IO, eset::ExpressionSet)
    println(io,
            "ExpressionSet with $(size(eset.exprs, 1)) rows and $(size(eset.exprs, 2)) columns")
    println(io,
            "Phenotype data: $(size(eset.phenotype_data, 1)) rows and $(size(eset.phenotype_data, 2)) columns")
    println(io,
            "Feature data: $(size(eset.feature_data, 1)) rows and $(size(eset.feature_data, 2)) columns")
    println("Experiment data: Please use experiment_data() on this struct to print the additional information.")
    return println(io, "Annotation: $(eset.annotation)")
end

function ==(eset1::ExpressionSet, eset2::ExpressionSet)
    return eset1.exprs == eset2.exprs &&
           eset1.phenotype_data == eset2.phenotype_data &&
           eset1.feature_data == eset2.feature_data &&
           eset1.experiment_data == eset2.experiment_data &&
           eset1.annotation == eset2.annotation
end

"""
    feature_names(eset::ExpressionSet)::Vector{String}

Extracts the feature names from an ExpressionSet.
"""
function feature_names(eset::ExpressionSet)::Vector{String}
    data = feature_data(eset)
    return data[!, :feature_names]
end
"""
    sample_names(eset::ExpressionSet)::Vector{String}

Extracts the sample names from an ExpressionSet.
"""
function sample_names(eset::ExpressionSet)::Vector{String}
    data = phenotype_data(eset)
    return data[!, :sample_names]
end

"""
    expression_values(eset::ExpressionSet)::DataFrame

Extracts the expression values from an ExpressionSet. The feature names are included as a column.

By passing the type `Matrix` as the first argument, the function will return the expression values as a matrix.
"""
function expression_values(eset::ExpressionSet)::DataFrame
    df = DataFrame(eset.exprs, sample_names(eset))
    df[!, :feature_names] = feature_names(eset)

    # Put feature_names as the first column
    select!(df, circshift(names(df), 1))
    return df
end

function expression_values(::Type{Matrix}, eset::ExpressionSet)::Matrix
    return eset.exprs
end

"""
    feature_data(eset::ExpressionSet)::DataFrame

Extracts the feature data from an ExpressionSet.
"""
function feature_data(eset::ExpressionSet)::DataFrame
    return eset.feature_data
end

"""
    phenotype_data(eset::ExpressionSet)::DataFrame

Extracts the phenotype data from an ExpressionSet.
"""
function phenotype_data(eset::ExpressionSet)::DataFrame
    return eset.phenotype_data
end

"""
    experiment_data(eset::ExpressionSet)::MIAME

Extracts the experiment data from an ExpressionSet.

# See also
[`MIAME`](@ref)
"""
function experiment_data(es::ExpressionSet)::MIAME
    return es.experiment_data
end

"""
    annotation(eset::ExpressionSet)::Symbol

Extracts the annotation from an ExpressionSet.
"""
function annotation(es::ExpressionSet)::Symbol
    return es.annotation
end

# Note: R interoperability functions have been moved to ExpressionDataInterop.jl

# Create a function to generate random ExpressionSet
function rand(::Type{ExpressionSet}, n::Int, p::Int)
    exprs = rand(n, p)
    pheno_data = DataFrame(; sample_names=["sample_$i" for i in 1:p])
    feature_data = DataFrame(; feature_names=["$i" for i in 1:n])
    experiment_data = MIAME(;
                            name="Name",
                            lab="Lab",
                            contact="Contact",
                            title="Title",
                            abstract="Abstract",
                            url="URL",
                            samples=["sample_$i" for i in 1:p],
                            hybridizations=["Hybridization1", "Hybridization2"],
                            norm_controls=["Control1", "Control2"],
                            preprocessing=["Preprocessing1", "Preprocessing2"],
                            pub_med_id="ID1",
                            other=Dict(:key1 => "value1", :key2 => "value2"))
    annotation = :Random

    return ExpressionSet(exprs, pheno_data, feature_data, experiment_data, annotation)
end

"""
    subset(eset::ExpressionSet; samples=nothing, features=nothing)

Create a subset of an ExpressionSet by selecting specific samples and/or features.

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
        if samples isa AbstractVector{<:AbstractString}
            # Sample names provided
            sample_indices = [findfirst(==(name), sample_names(eset)) for name in samples]
            if any(isnothing, sample_indices)
                error("Some sample names not found in ExpressionSet")
            end
        else
            # Sample indices provided
            sample_indices = samples
        end

        new_exprs = eset.exprs[:, sample_indices]
        new_pheno_data = eset.phenotype_data[sample_indices, :]
        new_samples = eset.experiment_data.samples[sample_indices]
    else
        new_exprs = eset.exprs
        new_pheno_data = eset.phenotype_data
        new_samples = eset.experiment_data.samples
    end

    # Handle feature subsetting
    if features !== nothing
        if features isa AbstractVector{<:AbstractString}
            # Feature names provided
            feature_indices = [findfirst(==(name), feature_names(eset))
                               for name in features]
            if any(isnothing, feature_indices)
                error("Some feature names not found in ExpressionSet")
            end
        else
            # Feature indices provided
            feature_indices = features
        end

        new_exprs = new_exprs[feature_indices, :]
        new_feature_data = eset.feature_data[feature_indices, :]
    else
        new_feature_data = eset.feature_data
    end

    # Create new MIAME with updated sample list
    new_experiment_data = MIAME(;
                                name=eset.experiment_data.name,
                                lab=eset.experiment_data.lab,
                                contact=eset.experiment_data.contact,
                                title=eset.experiment_data.title,
                                abstract=eset.experiment_data.abstract,
                                url=eset.experiment_data.url,
                                pub_med_id=eset.experiment_data.pub_med_id,
                                samples=new_samples,
                                hybridizations=eset.experiment_data.hybridizations,
                                norm_controls=eset.experiment_data.norm_controls,
                                preprocessing=eset.experiment_data.preprocessing,
                                other=eset.experiment_data.other)

    return ExpressionSet(new_exprs, new_pheno_data, new_feature_data, new_experiment_data,
                         eset.annotation)
end

"""
    combine(esets::Vector{ExpressionSet})

Combine multiple ExpressionSets into a single ExpressionSet.
All ExpressionSets must have the same features.

# Examples
```julia
combined_eset = combine([eset1, eset2, eset3])
```
"""
function combine(esets::Vector{ExpressionSet})
    if length(esets) == 0
        error("Cannot combine empty vector of ExpressionSets")
    end

    if length(esets) == 1
        return esets[1]
    end

    # Check that all have same features
    first_features = feature_names(esets[1])
    for eset in esets[2:end]
        if feature_names(eset) != first_features
            error("All ExpressionSets must have the same features to combine")
        end
    end

    # Combine expression data
    combined_exprs = hcat([eset.exprs for eset in esets]...)

    # Combine phenotype data
    combined_pheno_data = vcat([eset.phenotype_data for eset in esets]...)

    # Use feature data from first ExpressionSet
    combined_feature_data = esets[1].feature_data

    # Combine experiment data
    combined_experiment_data = reduce(merge, [eset.experiment_data for eset in esets])

    # Use annotation from first ExpressionSet
    combined_annotation = esets[1].annotation

    return ExpressionSet(combined_exprs, combined_pheno_data, combined_feature_data,
                         combined_experiment_data, combined_annotation)
end
