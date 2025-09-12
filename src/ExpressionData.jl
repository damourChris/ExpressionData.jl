module ExpressionData

using Arrow: Arrow
using DataFrames: DataFrames, DataFrame, Missing, Not, select!
using HDF5: HDF5, create_group, h5open
using JLD2: JLD2, load, save
using Serialization: Serialization, deserialize, serialize

include("miame.jl")
export MIAME,
       abstract,
       info,
       hybridizations,
       norm_controls,
       other,
       notes,
       preprocessing,
       pub_med_id

include("expression_set.jl")
export ExpressionSet,
       feature_names,
       sample_names,
       expression_values,
       experiment_data,
       feature_data,
       phenotype_data,
       annotation,
       get_sample_metadata,
       get_feature_metadata,
       has_experiment_data,
       subset,
       combine

include("io.jl")
export save_eset,
       save_eset_jld2,
       save_eset_hdf5,
       save_eset_arrow,
       load_eset,
       load_eset_jld2,
       load_eset_hdf5,
       load_eset_arrow

end
