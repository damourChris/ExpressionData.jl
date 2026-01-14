#!/usr/bin/env julia

# Data Analysis Example for ExpressionData.jl
# This example demonstrates basic data analysis operations with ExpressionSet objects

using ExpressionData
using Random
using Statistics

Random.seed!(101112)

# Create a more realistic gene expression dataset
n_genes = 12
n_samples = 8
base_expression = 10.0

# Create expression data with some biological patterns
expression_matrix = randn(n_genes, n_samples) .+ base_expression

# Make some genes differentially expressed between conditions
# Genes 1-4: upregulated in treatment
# Genes 5-8: downregulated in treatment
# Genes 9-12: no change
treatment_samples = [2, 4, 6, 8]  # Even-numbered samples are treated

for gene in 1:4  # Upregulated genes
    expression_matrix[gene, treatment_samples] .+= rand(4) .+ 7.0
end

for gene in 5:8  # Downregulated genes
    expression_matrix[gene, treatment_samples] .-= rand(4) .+ 5.5
end

genes = ["UPREGULATED_$i" for i in 1:4] ∪
        ["DOWNREGULATED_$i" for i in 1:4] ∪
        ["UNCHANGED_$i" for i in 1:4]

samples = ["Sample_$i" for i in 1:n_samples]

# Create metadata
sample_metadata = Dict{Symbol,Vector{Any}}(:condition => repeat(["Control", "Treatment"], 4),
                                           :replicate => [1, 1, 2, 2, 3, 3, 4, 4],
                                           :batch => [1, 1, 1, 1, 2, 2, 2, 2])

feature_metadata = Dict{Symbol,Vector{Any}}(:gene_class => repeat(["upregulated",
                                                                   "downregulated",
                                                                   "unchanged"]; inner=4),
                                            :chromosome => rand(1:22, n_genes))

eset = ExpressionSet(expression_matrix,
                     samples,
                     genes,
                     sample_metadata,
                     feature_metadata)

# Basic descriptive statistics

expr_matrix = expression_values(Matrix, eset)

# Dataset dimensions
size(eset)

# Expression statistics

# Min and max expression value
minimum(expr_matrix)
maximum(expr_matrix)

# Mean and std expression value
mean(expr_matrix)

# Standard deviation of expression values
std(expr_matrix)

## Sample-wise analysis
sample_data = phenotype_data(eset)
control_samples = sample_data[sample_data.condition .== "Control", :sample_names]
treatment_samples = sample_data[sample_data.condition .== "Treatment", :sample_names]

# Calculate mean expression per condition
control_indices = [findfirst(==(s), sample_names(eset)) for s in control_samples]
treatment_indices = [findfirst(==(s), sample_names(eset)) for s in treatment_samples]

control_means = mean(expr_matrix[:, control_indices]; dims=2)
treatment_means = mean(expr_matrix[:, treatment_indices]; dims=2)

# Mean expression by condition
for (i, gene) in enumerate(feature_names(eset))
    ctrl_mean = round(control_means[i]; digits=2)
    treat_mean = round(treatment_means[i]; digits=2)
    fold_change = round(treat_mean / ctrl_mean; digits=2)
    @info "$gene: Control=$ctrl_mean, Treatment=$treat_mean, FC=$fold_change"
end

# Gene-wise analysis

# Find most variable genes
gene_variances = var(expr_matrix; dims=2)
sorted_indices = sortperm(vec(gene_variances); rev=true)

# Most variable genes
for i in 1:5
    gene_idx = sorted_indices[i]
    gene_name = feature_names(eset)[gene_idx]
    variance = round(gene_variances[gene_idx]; digits=2)
    @info "  $gene_name: variance = $variance"
end

# Differential expression analysis (simple fold change)

log2_fold_changes = log2.(treatment_means ./ control_means)
abs_fold_changes = abs.(vec(log2_fold_changes))

# Find genes with |log2 FC| > 1 (2-fold change)
de_threshold = 1.0
de_indices = findall(x -> x > de_threshold, abs_fold_changes)

# Differentially expressed genes (|log2 FC| > de_threshold)
for idx in de_indices
    gene_name = feature_names(eset)[idx]
    fc = round(log2_fold_changes[idx]; digits=2)
    direction = fc > 0 ? "UP" : "DOWN"
    @info "$gene_name: log2 FC = $fc ($direction)"
end

# Subsetting analysis

# Subset to only differentially expressed genes
de_gene_names = feature_names(eset)[de_indices]
de_eset = ExpressionData.subset(eset; features=de_gene_names)

# Original genes:
feature_names(eset)

# DE gene names:
feature_names(de_eset)

# Subset to only one batch
batch1_samples = sample_data[sample_data.batch .== 1, :sample_names]
batch1_eset = ExpressionData.subset(eset; samples=batch1_samples)

# Original samples
sample_names(eset)
# Batch 1 samples
sample_names(batch1_eset)

# Quality control metrics

# Sample correlation
sample_correlations = cor(expr_matrix)

# Mean inter-sample correlation
mean_correlation = mean(sample_correlations[sample_correlations .< 1.0])  # Exclude diagonal

# Check for outlier samples (based on mean expression)
sample_means = mean(expr_matrix; dims=1)
sample_mean_std = std(vec(sample_means))
sample_mean_mean = mean(sample_means)

# Sample mean expressions
for (i, sample) in enumerate(sample_names(eset))
    sample_mean = round(sample_means[i]; digits=2)
    z_score = round((sample_means[i] - sample_mean_mean) / sample_mean_std; digits=2)
    outlier = abs(z_score) > 2 ? " (potential outlier)" : ""
    @info "$sample: $sample_mean (z-score: $z_score)$outlier"
end
