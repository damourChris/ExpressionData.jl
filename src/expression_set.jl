import Base.show
import RCall.rcopy

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

function feature_names(eset::ExpressionSet)::Vector{String}
    data = feature_data(eset)
    return data[!, :feature_names]
end

function sample_names(eset::ExpressionSet)::Vector{String}
    data = phenotype_data(eset)
    return data[!, :sample_names]
end

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

function feature_data(eset::ExpressionSet)::DataFrame
    return eset.feature_data
end

function phenotype_data(eset::ExpressionSet)::DataFrame
    return eset.phenotype_data
end

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
