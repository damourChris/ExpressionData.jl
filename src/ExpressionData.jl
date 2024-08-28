module ExpressionData

using DataFrames
using JLD2
using RCall: @rget
using Serialization

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
       expression_values,
       expression_values!,
       feature_data,
       feature_data!,
       phenotype_data,
       phenotype_data!,
       annotation

end
