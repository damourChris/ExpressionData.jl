import Base.show
import Base.==
import RCall.rcopy

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

function show(eset::ExpressionSet)
    println("ExpressionSet with $(size(eset.exprs, 1)) rows and $(size(eset.exprs, 2)) columns")
    println("Phenotype data: $(size(eset.phenotype_data, 1)) rows and $(size(eset.phenotype_data, 2)) columns")
    println("Feature data: $(size(eset.feature_data, 1)) rows and $(size(eset.feature_data, 2)) columns")
    println("Experiment data: $(eset.experiment_data)")
    return println("Annotation: $(eset.annotation)")
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

function rcopy(::Type{ExpressionSet}, s::Ptr{S4Sxp})
    R"""
    library(Biobase)    
    sample_names <- sampleNames($s) 
    feature_names <- featureNames($s) 
    annotation <- annotation($s) 
    e_data <- $s@experimentData
    """

    sample_names = @rget sample_names
    feature_names = @rget feature_names
    annotation = @rget annotation
    e_data_R = @rget e_data

    exprs = rcopy(Matrix{Float64}, s[:assayData][:exprs])

    p_data = rcopy(DataFrame, s[:phenoData][:data])
    p_data[!, :sample_names] = sample_names

    f_data = rcopy(DataFrame, s[:featureData][:data])
    f_data[!, :feature_names] = feature_names

    e_data = rcopy(MIAME, e_data_R)

    ann = Symbol(annotation)

    return ExpressionSet(exprs, p_data, f_data, e_data, ann)
end
