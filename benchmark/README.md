# ExpressionData.jl Benchmarks

This directory contains benchmarks for ExpressionData.jl performance evaluation.

## Overview

The benchmarking suite aims to evaluates the performance-critical functions across different data sizes and file formats.

## Usage

### Running All Benchmarks

```bash
cd benchmark/
julia benchmarks.jl
```

### Running from Julia REPL

```julia
include("benchmark/benchmarks.jl")
main()
```

## Test Data Sizes

- **Small**: 100 genes × 10 samples
- **Medium**: 1000 genes × 100 samples
- **Large**: 10000 genes × 1000 samples

## Output Metrics

For each operation, the benchmark reports:

- **Median execution time** (formatted as ns/μs/ms/s)
- **Memory allocation** (formatted as B/KB/MB/GB)
- **File size** (for I/O operations)
