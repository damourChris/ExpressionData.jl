```@meta
CurrentModule = ExpressionData
```

# Saving and loading data

The `ExpressionData` package provides functions for saving and loading gene expression data in various Julia-native formats for optimal performance and interoperability.

## Supported Formats

- **HDF5** (`.h5`, `.hdf5`): Cross-platform format with excellent compression, widely supported. Recommended for large datasets.
- **JLD2** (`.jld2`): Julia-specific format.
- **Arrow** (`.arrow`): Columnar format optimized for analytical workloads, good for data exchange.
- **Julia Serialization** (`.jls`, `.dat`): Native Julia serialization for quick prototyping.

## Large Datasets

For large datasets, HDF5 is recommended due to its efficient storage and access patterns. The `save_eset_hdf5` and `load_eset_hdf5` functions handle HDF5 files.

## Saving

The [`save_eset`](@ref) function automatically detects the format from the file extension and saves accordingly.

```@docs
ExpressionData.save_eset
ExpressionData.save_eset_jld2
ExpressionData.save_eset_hdf5
ExpressionData.save_eset_arrow
```

## Loading

The [`load_eset`](@ref) function automatically detects the format and loads accordingly.

```@docs
ExpressionData.load_eset
ExpressionData.load_eset_jld2
ExpressionData.load_eset_hdf5
ExpressionData.load_eset_arrow
```

## Examples

```julia
# Save in different formats
save_eset(my_eset, "data.h5")      # HDF5 format (recommended)
save_eset(my_eset, "data.jld2")    # JLD2 format
save_eset(my_eset, "data.arrow")   # Arrow format
save_eset(my_eset, "data.jls")     # Julia serialization

# Load automatically detects format
eset1 = load_eset("data.jld2")
eset2 = load_eset("data.h5")
eset3 = load_eset("data.arrow")
```
