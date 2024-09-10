"""
    save_eset(eset::ExpressionSet, file::AbstractString)

Saves an `ExpressionSet` object to a file. The file is saved in a serialized format.
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

    return serialize(file, data)
end

"""
    load_eset(file::AbstractString)::ExpressionSet

Loads an `ExpressionSet` object from a file. The file should be in a serialized format.
To save an object, use `save_eset`.

# See also
[`save_eset`](@ref)
"""
function load_eset(file::AbstractString)::ExpressionSet
    # if the extension is .rds then we load it with readRDS and convert
    if endswith(file, ".rds")
        R"""
        eset_file <- readRDS($file) 

        # Check if the object is an ExpressionSet
        if (!is(eset_file, "ExpressionSet")) {
            # Try accessing the first element
            if (!is(eset_file[[1]], "ExpressionSet")) {
                stop("The object in the file is not an ExpressionSet")
            }
            eset <- eset_file[[1]]
        }else{
            eset <- eset_file
        } 
        """

        eset_R = @rget eset
        return convert(ExpressionSet, eset_R)
    end

    data = deserialize(file)

    return ExpressionSet(data["exprs"],
                         data["phenotype_data"],
                         data["feature_data"],
                         data["experiment_data"],
                         data["annotation"])
end
