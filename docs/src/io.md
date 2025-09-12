```@meta
CurrentModule = ExpressionData
```

# Saving and loading data

The `ExpressionData` package provides functions for saving and loading gene expression data in various formats.

## Saving

The [`save_eset`](@ref) function saves gene expression data to a file in a specified format.

```@docs
ExpressionData.save_eset
```

## Loading

The [`load_eset`](@ref) function loads gene expression data from a file saved through save_eset.
Support reading from RDS files is also provided.

```@docs

ExpressionData.load_eset
```
