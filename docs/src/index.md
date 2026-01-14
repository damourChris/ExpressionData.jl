```@meta
CurrentModule = ExpressionData
```

# ExpressionData

ExpressionData.jl provides Julia-native data structures and functionality for working with gene expression datasets. It implements the core concepts from Bioconductor's ExpressionSet and MIAME classes, but with a pure Julia implementation optimized for performance and interoperability with the Julia data science ecosystem.

## Key Features

- **File Formats**: Support for JLD2, HDF5, Arrow, and Julia serialization
- **DataFrame Integration**: Seamless integration with DataFrames.jl
- **High Performance**: Optimized for Julia's strengths in numerical computing
- **Extensible**: Easy to extend with additional functionality

## Quick Start

```julia
using ExpressionData

# Create an ExpressionSet
eset = ExpressionSet(
    rand(100, 20),  # 100 genes, 20 samples
    DataFrame(sample_names=["Sample_$i" for i in 1:20]),
    DataFrame(feature_names=["Gene_$i" for i in 1:100]),
    MIAME(name="My Experiment", lab="My Lab", contact="researcher@university.edu",
          title="Gene Expression Study", abstract="Description of the study",
          url="", pub_med_id="", samples=String[], hybridizations=String[],
          norm_controls=String[], preprocessing=String[], other=Dict{Symbol,String}()),
    :MyPlatform
)

# Access data
expression_matrix = expression_values(Matrix, eset)
sample_info = phenotype_data(eset)
gene_info = feature_data(eset)

# Save in different formats
save_eset(eset, "my_data.jld2")  # Recommended format
save_eset(eset, "my_data.h5")    # HDF5 for cross-platform compatibility
save_eset(eset, "my_data.arrow") # Arrow for analytical workloads

# Load data
eset_loaded = load_eset("my_data.jld2")
```

## Contents

```@index
```
