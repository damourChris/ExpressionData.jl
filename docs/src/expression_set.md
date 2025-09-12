```@meta
CurrentModule = ExpressionData
```

# Expression Sets

The `ExpressionSet` type is a container for storing gene expression data. Following the Bioconductor `ExpressionSet` class, it contains a matrix of expression values, a matrix of feature data, and a matrix of sample data.

## Constructor

```@docs
ExpressionData.ExpressionSet
```

## Accessors

```@docs
ExpressionData.expression_values
ExpressionData.feature_data
ExpressionData.phenotype_data
ExpressionData.experiment_data
ExpressionData.annotation
ExpressionData.sample_names
ExpressionData.feature_names
```
