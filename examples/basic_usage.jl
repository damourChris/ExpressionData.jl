#!/usr/bin/env julia

# Basic Usage Example for ExpressionData.jl
# This example demonstrates the fundamental operations with ExpressionSet objects

using ExpressionData
using Statistics

# Generate some synthetic expression data (genes x samples)
n_genes = 5
n_samples = 3
expression_matrix = randn(n_genes, n_samples) .+ 10  # Add baseline expression

# Define gene and sample names
genes = ["GENE_" * string(i) for i in 1:n_genes]
samples = ["Sample_" * string(i) for i in 1:n_samples]

# Create the ExpressionSet
eset = ExpressionSet(expression_matrix, samples, genes)

# "Number of genes
length(feature_names(eset))
length(sample_names(eset))

# Can also use size function
size(eset)

# Gene names
feature_names(eset)

# Sample names
sample_names(eset)

# Now we can access the expression data in different formats
expr_df = expression_values(eset)

# Get as Matrix
expr_matrix = expression_values(Matrix, eset)

# Access specific values
gene_list = feature_names(eset)
sample_list = sample_names(eset)

# Basic data exploration
# Min expression value
minimum(expr_matrix)

# Max expression value
maximum(expr_matrix)

# Mean expression value
mean(expr_matrix)
