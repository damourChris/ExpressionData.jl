function save_eset(eset::ExpressionSet, file::AbstractString)
    return data = Dict("exprs" => eset.exprs,
                       "feature_data" => eset.feature_data,
                       "phenotype_data" => eset.phenotype_data,
                       "experiment_data" => eset.experiment_data,
                       "annotation" => eset.annotation)

    return serialize(file, data)
end

function load_eset(file::AbstractString)::ExpressionSet
    data = deserialize(file)

    return ExpressionSet(data["exprs"],
                         data["phenotype_data"],
                         data["feature_data"],
                         data["experiment_data"],
                         data["annotation"])
end
