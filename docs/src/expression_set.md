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
ExpressionData.annotation
```

## Manipulation
```@docs
ExpressionData.select_features
ExpressionData.select_samples
ExpressionData.select_phenotypes
ExpressionData.select_annotations
ExpressionData.select
ExpressionData.merge
ExpressionData.split
ExpressionData.filter
ExpressionData.normalize
ExpressionData.scale
ExpressionData.impute
ExpressionData.center
ExpressionData.log2
ExpressionData.remove
ExpressionData.remove_features
ExpressionData.remove_samples
ExpressionData.remove_phenotypes
ExpressionData.remove_annotations
ExpressionData.remove_missing
ExpressionData.remove_low_variance
ExpressionData.remove_outliers
ExpressionData.remove_correlated
ExpressionData.remove_duplicates
ExpressionData.remove_uninformative
```

## Visualization
```@docs
ExpressionData.plot
ExpressionData.plot_pca
ExpressionData.plot_heatmap
ExpressionData.plot_correlation
ExpressionData.plot_density
ExpressionData.plot_volcano
ExpressionData.plot_boxplot
ExpressionData.plot_violin
ExpressionData.plot_scatter
ExpressionData.plot_line
ExpressionData.plot_bar
ExpressionData.plot_histogram
ExpressionData.plot_dendrogram
ExpressionData.plot_network
ExpressionData.plot_pathway
ExpressionData.plot_gsea
```

## Analysis
```@docs
ExpressionData.cluster
ExpressionData.cluster_features
ExpressionData.cluster_samples
ExpressionExpressionData.cluster_phenotypes
ExpressionData.cluster_annotations
ExpressionData.cluster_correlation
ExpressionData.cluster_density
ExpressionData.cluster_volcano
ExpressionData.cluster_boxplot
ExpressionData.cluster_violin
ExpressionData.cluster_scatter
ExpressionData.cluster_line
ExpressionData.cluster_bar
ExpressionData.cluster_histogram
ExpressionData.cluster_dendrogram
ExpressionData.cluster_network
ExpressionData.cluster_pathway
ExpressionData.cluster_gsea
```

## Export
```@docs
ExpressionData.write
ExpressionData.write_expression
ExpressionData.write_feature
ExpressionData.write_phenotype
ExpressionData.write_annotation
ExpressionData.write_gct
ExpressionData.write_gmt
ExpressionData.write_gsea
ExpressionData.write_gsea_rank
ExpressionData.write_gsea_gene
ExpressionData.write_gsea_set
ExpressionData.write_gsea_table
ExpressionData.write_gsea_plot
ExpressionData.write_gsea_report
ExpressionData.write_gsea_html
ExpressionData.write_gsea_pdf
ExpressionData.write_gsea_png
ExpressionData.write_gsea_svg
ExpressionData.write_gsea_jpg
ExpressionData.write_gsea_tiff
ExpressionData.write_gsea_bmp
ExpressionData.write_gsea_emf
ExpressionData.write_gsea_eps
ExpressionData.write_gsea_ps
ExpressionData.write_gsea_latex
ExpressionData.write_gsea_tex
ExpressionData.write_gsea_pdf
ExpressionData.write_gsea_md
ExpressionData.write_gsea_html
ExpressionData.write_gsea_doc
ExpressionData.write_gsea_docx
ExpressionData.write_gsea_odt
ExpressionData.write_gsea_rtf
ExpressionData.write_gsea_txt
ExpressionData.write_gsea_csv
ExpressionData.write_gsea_tsv
ExpressionData.write_gsea_xls
ExpressionData.write_gsea_xlsx
ExpressionData.write_gsea_dta
ExpressionData.write_gsea_feather
ExpressionData.write_gsea_parquet
ExpressionData.write_gsea_msgpack
ExpressionData.write_gsea_stata
ExpressionData.write_gsea_sas
ExpressionData.write_gsea_spss
ExpressionData.write_gsea_jmp
```

## Import
```@docs
ExpressionData.read
ExpressionData.read_expression
ExpressionData.read_feature
ExpressionData.read_phenotype
ExpressionData.read_annotation
ExpressionData.read_gct
ExpressionData.read_gmt
ExpressionData.read_gsea
ExpressionData.read_gsea_rank
ExpressionData.read_gsea_gene
ExpressionData.read_gsea_set
```

## Utilities
```@docs
ExpressionData.download
ExpressionData.download_gct
ExpressionData.download_gmt
ExpressionData.download_gsea
ExpressionData.download_gsea_rank
ExpressionData.download_gsea_gene
ExpressionData.download_gsea_set
ExpressionData.download_gsea_table
ExpressionData.download_gsea_plot
ExpressionData.download_gsea_report
ExpressionData.download_gsea_html
ExpressionData.download_gsea_pdf
ExpressionData.download_gsea_png
```





