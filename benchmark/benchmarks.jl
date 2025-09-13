#!/usr/bin/env julia
"""
Comprehensive benchmarking suite for ExpressionData.jl

This script benchmarks the most performance-critical functions across different
data sizes and file formats to evaluate the pure Julia implementation performance.
"""

using BenchmarkTools
using DataFrames
using ExpressionData
using Printf
using Random
using Statistics
using Dates
using JSON3
using PrettyTables
using ProgressMeter
using Base.Threads
using Pkg: Pkg;
using InteractiveUtils: versioninfo

# Set random seed for reproducible benchmarks
Random.seed!(42)

println("🚀 ExpressionData.jl Benchmark Suite")
println("=====================================")

# Define benchmark data sizes
const BENCHMARK_SIZES = [(name="Small", genes=100, samples=10),
                         (name="Medium", genes=1000, samples=100),
                         (name="Large", genes=10000, samples=1000),
                         (name="Large (Genes)", genes=100000, samples=100),
                         (name="Large (Samples)", genes=100, samples=100000)]

# Define file formats to test
const FILE_FORMATS = [(ext=".jld2", name="JLD2"),
                      (ext=".h5", name="HDF5"),
                      (ext=".arrow", name="Arrow"),
                      (ext=".jls", name="Julia Serialization")]

# Structure to store benchmark results
mutable struct BenchmarkResults
    metadata::Dict{String,Any}
    creation::Vector{Dict{String,Any}}
    data_access::Vector{Dict{String,Any}}
    data_manipulation::Vector{Dict{String,Any}}
    io_operations::Vector{Dict{String,Any}}

    function BenchmarkResults()
        # Constrcut metadata ased on versioninfo()
        io = IOBuffer()
        versioninfo(io)
        metadata = Dict{String,Any}()
        lines = split(String(take!(io)), '\n')
        # Read and parse versioninfo output
        for line in lines
            if occursin("Julia Version", line)
                metadata["julia_version"] = strip(split(line, "Julia Version")[2])
            elseif occursin("Commit", line)
                metadata["julia_commit"] = strip(split(line, "Commit")[2])
            elseif occursin("OS", line)
                metadata["platform"] = strip(split(line, ":")[2])
            elseif occursin("CPU", line)
                metadata["cpu"] = strip(split(line, ":")[2])
            end
        end

        metadata["threads"] = nthreads()
        metadata["timestamp"] = string(Dates.now())

        return new(metadata, [], [], [], [])
    end
end

"""
    create_test_data(n_genes::Int, n_samples::Int) -> ExpressionSet

Create test ExpressionSet with specified dimensions.
"""
function create_test_data(n_genes::Int, n_samples::Int)
    exprs = rand(n_genes, n_samples)
    sample_names = ["Sample_$i" for i in 1:n_samples]
    feature_names = ["Gene_$i" for i in 1:n_genes]

    # Empty metadata dictionaries for benchmarking
    sample_metadata = Dict{Symbol,Vector{Any}}()
    feature_metadata = Dict{Symbol,Vector{Any}}()

    experiment_data = MIAME(;
                            name="Benchmark Dataset",
                            lab="Benchmark Lab",
                            contact="benchmark@test.com",
                            title="Performance Test Data",
                            abstract="Generated data for benchmarking ExpressionData.jl",
                            url="",
                            pub_med_id="",
                            samples=sample_names,
                            hybridizations=String[],
                            norm_controls=String[],
                            preprocessing=String[],
                            other=Dict{Symbol,String}())

    return ExpressionSet(exprs, sample_names, feature_names, sample_metadata,
                         feature_metadata, experiment_data, :benchmark)
end

"""
    format_time(t::Float64) -> String

Format time in human-readable format.
"""
function format_time(t::Float64)
    if t < 1e-6
        return @sprintf("%.2f ns", t * 1e9)
    elseif t < 1e-3
        return @sprintf("%.2f μs", t * 1e6)
    elseif t < 1.0
        return @sprintf("%.2f ms", t * 1e3)
    else
        return @sprintf("%.2f s", t)
    end
end

"""
    format_memory(bytes::Int) -> String

Format memory usage in human-readable format.
"""
function format_memory(bytes::Int)
    if bytes < 1024
        return "$bytes B"
    elseif bytes < 1024^2
        return @sprintf("%.2f KB", bytes / 1024)
    elseif bytes < 1024^3
        return @sprintf("%.2f MB", bytes / 1024^2)
    else
        return @sprintf("%.2f GB", bytes / 1024^3)
    end
end
function format_memory(bytes::Float64)
    return format_memory(Int(round(bytes)))
end

"""
    display_results_tables(results::BenchmarkResults)

Display benchmark results using PrettyTables for better formatting.
"""
function display_results_tables(io::IO, results::BenchmarkResults)
    println(io,
            """
ExpressionData.jl Benchmark Results
$("="^50)
Julia version: $(results.metadata["julia_version"])
Threads: $(results.metadata["threads"])
Timestamp: $(results.metadata["timestamp"])
CPU: $(get(results.metadata, "cpu", "unknown"))
Platform: $(get(results.metadata, "platform", "unknown"))
$("="^50)
Dataset sizes benchmarked:
$(join([@sprintf(" - %s: %d genes × %d samples", size.name, size.genes, size.samples) for size in BENCHMARK_SIZES], "\n"))
$("="^50)
""")

    # Texthighliter for ns times
    hl_ns = TextHighlighter((data, i, j) -> j > 1 && occursin("ns", data[i, j]),
                            crayon"blue")

    # Hilighter for μs
    hl_μs = TextHighlighter((data, i, j) -> j > 1 && occursin("μs", data[i, j]),
                            crayon"green")

    # Hilighter for ms
    hl_ms = TextHighlighter((data, i, j) -> j > 1 && occursin("ms", data[i, j]),
                            crayon"yellow")

    # Hilighter for s
    hl_s = TextHighlighter((data, i, j) -> j > 1 && occursin("s", data[i, j]),
                           crayon"red")

    time_hl = [hl_ns, hl_μs, hl_ms, hl_s]

    # Same for memory
    hl_B = TextHighlighter((data, i, j) -> j > 1
                                           && occursin("B", data[i, j]) &&
                                           !occursin("KB", data[i, j])
                                           && !occursin("MB", data[i, j]) &&
                                           !occursin("GB", data[i, j]),
                           crayon"blue")
    hl_KB = TextHighlighter((data, i, j) -> j > 1
                                            && occursin("KB", data[i, j]) &&
                                            !occursin("MB", data[i, j])
                                            && !occursin("GB", data[i, j]),
                            crayon"green")
    hl_MB = TextHighlighter((data, i, j) -> j > 1
                                            && occursin("MB", data[i, j]) &&
                                            !occursin("GB", data[i, j]),
                            crayon"yellow")
    hl_GB = TextHighlighter((data, i, j) -> j > 1 && occursin("GB", data[i, j]),
                            crayon"red")

    memory_hl = [hl_B, hl_KB, hl_MB, hl_GB]

    style = TextTableStyle(; first_line_column_label=crayon"magenta")
    table_format = TextTableFormat(; borders=text_table_borders__unicode_rounded)

    # Creation benchmarks table
    if !isempty(results.creation)

        # Here we want a table with:
        # - Colum1 : operations
        # - Colum2+ : each dataset isze
        # - Row 1: headers
        # - Row 2+ perations
        #--> row are grouped for time and memory
        operations = ["Create ExpressionSet" => "creation",
                      "Random ExpressionSet" => "random"]
        row_groups = ["Time" => "_time", "Memory" => "_memory"]
        creation_data = []

        for row_group in row_groups
            for op in operations
                row = [op[1]]
                for size_result in results.creation
                    metric = row_group[2]
                    key = op[2] * metric
                    op_result = size_result[key]
                    if metric == "_time"
                        push!(row, format_time(op_result))
                    else
                        push!(row, format_memory(op_result))
                    end
                end
                push!(creation_data, row)
            end
        end

        creation_data

        # Column labels are "operations" and dataset sizes
        dataset_sizes = [result["size_name"] for result in results.creation]

        println(io, "🏗️  ExpressionSet Creation Benchmark")
        pretty_table(io, permutedims(reduce(hcat, creation_data));
                     column_labels=["Operation", dataset_sizes...],
                     row_group_labels=[1 => "Time", 1 + length(operations) => "Memory"],
                     style=style,
                     fit_table_in_display_horizontally=false,
                     fit_table_in_display_vertically=false,
                     table_format=table_format,
                     highlighters=[time_hl..., memory_hl...],
                     merge_column_label_cells=:auto,
                     alignment=[:l, repeat([:r], length(dataset_sizes))...])

        println(io)
    end

    # Data access benchmarks table
    if !isempty(results.data_access)
        access_data = []

        # Here we want a table with the same structure as creation:
        # - Column1: operations
        # - Column2+: each dataset size
        # - Rows are grouped for time and memory
        row_groups = ["Time" => "time", "Memory" => "memory"]

        for row_group in row_groups
            for op_index in 1:length(results.data_access[1]["operations"])
                row = [results.data_access[1]["operations"][op_index]["name"]]
                for size_result in results.data_access
                    op = size_result["operations"][op_index]
                    metric = row_group[2]
                    if metric == "time"
                        push!(row, format_time(op[metric]))
                    else
                        push!(row, format_memory(op[metric]))
                    end
                end
                push!(access_data, row)
            end
        end

        dataset_sizes = [result["size_name"] for result in results.data_access]
        num_operations = length(results.data_access[1]["operations"])

        println(io, "🔍 Data Access Operations Benchmark")
        pretty_table(io, permutedims(reduce(hcat, access_data));
                     column_labels=["Operation", dataset_sizes...],
                     row_group_labels=[1 => "Time", 1 + num_operations => "Memory"],
                     style=style,
                     fit_table_in_display_horizontally=false,
                     fit_table_in_display_vertically=false,
                     table_format=table_format,
                     highlighters=[time_hl..., memory_hl...],
                     merge_column_label_cells=:auto,
                     alignment=[:l, repeat([:r], length(dataset_sizes))...])
        println(io)
    end

    # Data manipulation benchmarks table
    if !isempty(results.data_manipulation)

        # Here we want a table with the same structure as creation:
        # - Column1: operations
        # - Column2+: each dataset size
        # - Rows are grouped for time and memory
        manipulation_data = []
        row_groups = ["Time" => "time", "Memory" => "memory"]

        for row_group in row_groups
            for op_index in 1:length(results.data_manipulation[1]["operations"])
                row = [results.data_manipulation[1]["operations"][op_index]["name"]]
                for size_result in results.data_manipulation
                    op = size_result["operations"][op_index]
                    metric = row_group[2]
                    if metric == "time"
                        push!(row, format_time(op[metric]))
                    else
                        push!(row, format_memory(op[metric]))
                    end
                end
                push!(manipulation_data, row)
            end
        end

        dataset_sizes = [result["size_name"] for result in results.data_manipulation]
        num_operations = length(results.data_manipulation[1]["operations"])

        println(io, "🔧 Data Manipulation Operations Benchmark")
        pretty_table(io, permutedims(reduce(hcat, manipulation_data));
                     column_labels=["Operation", dataset_sizes...],
                     row_group_labels=[1 => "Time", 1 + num_operations => "Memory"],
                     style=style,
                     table_format=table_format,
                     fit_table_in_display_horizontally=false,
                     fit_table_in_display_vertically=false,
                     highlighters=[time_hl..., memory_hl...],
                     merge_column_label_cells=:auto,
                     alignment=[:l, repeat([:r], length(dataset_sizes))...])

        println(io)
    end
    results.io_operations[1]["formats"]
    # I/O operations benchmarks table
    if !isempty(results.io_operations)

        # Here we want a similar type of table
        # Be we want to display Save Time, Load time and File size on different rows,
        # Group by row_group_label
        #  So each row will be:
        #  - Format name
        #  - Time of the current row category (Save, Load, Size) for each dataset size

        io_data = []

        for row_category in ["load_time", "save_time", "file_size"]
            for format_index in 1:length(results.io_operations[1]["formats"])
                row = [results.io_operations[1]["formats"][format_index]["format_name"]]
                for size_result in results.io_operations
                    format_result = size_result["formats"][format_index]
                    if haskey(format_result, "error")
                        push!(row, "Error")
                    else
                        # Make the formatting conditional based on the row category
                        if row_category == "file_size"
                            push!(row, format_memory(format_result[row_category]))
                        else
                            push!(row, format_time(format_result[row_category]))
                        end
                    end
                end
                push!(io_data, row)
            end
        end

        # For the row group labels, from the docs:
        # The row group labels are specified by a Vector{Pair{Int, String}}. Each element defines a new row group label. The first element of the Pair is the row index of the row group and the second is the label. For example, [3 => "Row Group #1"] defines that before row 3, we have the row group label named "Row Group #1".
        # Since we have `length(FILE_FORMATS)` formats per category, the starting row for each category is:
        # - Save Time: 1
        # - Load Time: 1 + length(FILE_FORMATS)
        # - File Size: 1 + 2 * length(FILE_FORMATS)

        dataset_sizes = [result["size_name"] for result in results.io_operations]

        println(io, "📁 I/O Operations Benchmark")
        pretty_table(io, permutedims(reduce(hcat, io_data));
                     column_labels=["Format", dataset_sizes...],
                     row_group_labels=[1 => "Save Time",
                                       1 + length(FILE_FORMATS) => "Load Time",
                                       1 + 2 * length(FILE_FORMATS) => "File Size"],
                     style=style,
                     table_format=table_format,
                     fit_table_in_display_horizontally=false,
                     fit_table_in_display_vertically=false,
                     highlighters=[time_hl..., memory_hl...],
                     merge_column_label_cells=:auto,
                     alignment=[:l, repeat([:r], length(dataset_sizes))...])

        println(io)
    end
end

"""
    save_human_readable_results(results::BenchmarkResults, filename::String)

Save benchmark results in a human-readable format.
"""
function save_human_readable_results(results::BenchmarkResults, filename::String)
    # Redirect output to file while also displaying tables
    old_stdout = stdout
    open(filename, "w") do io
        return display_results_tables(io, results)
    end

    # Also display to console
    return display_results_tables(stdout, results)
end

"""
    save_machine_readable_results(results::BenchmarkResults, filename::String)

Save benchmark results in machine-readable JSON format.
"""
function save_machine_readable_results(results::BenchmarkResults, filename::String)
    open(filename, "w") do io
        return JSON3.pretty(io, results)
    end
end

"""
Benchmark a single I/O format operation (helper function for parallel execution)
"""
function benchmark_single_format(test_data, format, progress)
    format_result = Dict{String,Any}("format_name" => format.name)
    temp_file = tempname() * format.ext

    try
        # Benchmark save operation
        save_result = @benchmark save_eset($test_data, $temp_file) setup = (rm($temp_file;
                                                                               force=true))
        save_time = median(save_result.times) / 1e9
        save_memory = median(save_result.memory)

        # Benchmark load operation
        save_eset(test_data, temp_file)  # Ensure file exists
        load_result = @benchmark load_eset($temp_file)
        load_time = median(load_result.times) / 1e9
        load_memory = median(load_result.memory)

        # Get file size
        file_size = filesize(temp_file)

        # Store results
        format_result["save_time"] = save_time
        format_result["save_memory"] = save_memory
        format_result["load_time"] = load_time
        format_result["load_memory"] = load_memory
        format_result["file_size"] = file_size

    catch e
        format_result["error"] = string(e)
    finally
        rm(temp_file; force=true)
    end

    next!(progress)
    return format_result
end

"""
Benchmark I/O operations across different file formats (with optional parallelization)
"""
function benchmark_io_operations!(results::BenchmarkResults; parallel::Bool=true)
    println("\n📁 I/O Operations Benchmark")
    println(parallel ? "Running with $(nthreads()) threads" : "Running sequentially")
    println("="^50)

    total_tasks = length(BENCHMARK_SIZES) * length(FILE_FORMATS)
    progress = Progress(total_tasks, "I/O operations benchmarks: ")

    for size_config in BENCHMARK_SIZES

        # Create test data
        test_data = create_test_data(size_config.genes, size_config.samples)

        # Initialize result structure for this size
        size_result = Dict{String,Any}("size_name" => size_config.name,
                                       "genes" => size_config.genes,
                                       "samples" => size_config.samples,
                                       "formats" => [])

        if parallel && nthreads() > 1
            # Parallel execution using threads
            format_results = Vector{Dict{String,Any}}(undef, length(FILE_FORMATS))

            @threads for i in eachindex(FILE_FORMATS)
                format_results[i] = benchmark_single_format(test_data, FILE_FORMATS[i],
                                                            progress)
            end

            # Add results in order
            for format_result in format_results
                push!(size_result["formats"], format_result)
            end
        else
            # Sequential execution
            for format in FILE_FORMATS
                format_result = benchmark_single_format(test_data, format, progress)
                push!(size_result["formats"], format_result)
            end
        end

        push!(results.io_operations, size_result)
    end
end

"""
Benchmark a single data access operation (helper function for parallel execution)
"""
function benchmark_single_access_operation(test_data, op_name, op_func)
    result = @benchmark $op_func()
    time = median(result.times) / 1e9
    memory = median(result.memory)

    return Dict{String,Any}("name" => op_name,
                            "time" => time,
                            "memory" => memory)
end

"""
Benchmark data access operations (with optional parallelization)
"""
function benchmark_data_access!(results::BenchmarkResults; parallel::Bool=false)
    println("\n🔍 Data Access Operations Benchmark")
    if parallel && nthreads() > 1
        println("Running with $(nthreads()) threads")
    end
    println("="^50)

    progress = Progress(length(BENCHMARK_SIZES), "Data access benchmarks: ")
    for size_config in BENCHMARK_SIZES
        # println("\n$(size_config.name) Dataset ($(size_config.genes) genes × $(size_config.samples) samples):")

        # Create test data
        test_data = create_test_data(size_config.genes, size_config.samples)

        # Initialize result structure for this size
        size_result = Dict{String,Any}("size_name" => size_config.name,
                                       "genes" => size_config.genes,
                                       "samples" => size_config.samples,
                                       "operations" => [])

        # Benchmark core access functions
        operations = [("expression_values (DataFrame)", () -> expression_values(test_data)),
                      ("expression_values (Matrix)",
                       () -> expression_values(Matrix, test_data)),
                      ("feature_names", () -> feature_names(test_data)),
                      ("sample_names", () -> sample_names(test_data)),
                      ("phenotype_data", () -> phenotype_data(test_data)),
                      ("feature_data", () -> feature_data(test_data)),
                      ("experiment_data", () -> experiment_data(test_data))]

        if parallel && nthreads() > 1
            # Parallel execution using threads
            operation_results = Vector{Dict{String,Any}}(undef, length(operations))

            @threads for i in eachindex(operations)
                op_name, op_func = operations[i]
                operation_results[i] = benchmark_single_access_operation(test_data, op_name,
                                                                         op_func)
            end

            # Add results in order
            for op_result in operation_results
                push!(size_result["operations"], op_result)
            end
        else
            # Sequential execution
            for (op_name, op_func) in operations
                op_result = benchmark_single_access_operation(test_data, op_name, op_func)
                push!(size_result["operations"], op_result)
            end
        end

        push!(results.data_access, size_result)
        next!(progress)
    end
end

"""
Benchmark data manipulation operations
"""
function benchmark_data_manipulation!(results::BenchmarkResults)
    println("\n🔧 Data Manipulation Operations Benchmark")
    println("="^50)

    progress = Progress(length(BENCHMARK_SIZES), "Data manipulation benchmarks: ")
    for size_config in BENCHMARK_SIZES
        # println("\n$(size_config.name) Dataset ($(size_config.genes) genes × $(size_config.samples) samples):")

        # Create test data
        test_data = create_test_data(size_config.genes, size_config.samples)

        # Initialize result structure for this size
        size_result = Dict{String,Any}("size_name" => size_config.name,
                                       "genes" => size_config.genes,
                                       "samples" => size_config.samples,
                                       "operations" => [])

        # Benchmark subset operations
        n_samples_subset = min(5, size_config.samples ÷ 2)
        n_genes_subset = min(50, size_config.genes ÷ 2)

        sample_subset = sample_names(test_data)[1:n_samples_subset]
        gene_subset = feature_names(test_data)[1:n_genes_subset]

        operations = [("subset by samples",
                       () -> ExpressionData.subset(test_data; samples=sample_subset)),
                      ("subset by features",
                       () -> ExpressionData.subset(test_data; features=gene_subset)),
                      ("subset by both",
                       () -> ExpressionData.subset(test_data; samples=sample_subset,
                                                   features=gene_subset))]

        for (op_name, op_func) in operations
            result = @benchmark $op_func()
            time = median(result.times) / 1e9
            memory = median(result.memory)

            # println("  $op_name: $(format_time(time)) | $(format_memory(memory))")

            # Store result
            push!(size_result["operations"],
                  Dict{String,Any}("name" => op_name,
                                   "time" => time,
                                   "memory" => memory))
        end

        # Benchmark combine operation (create two datasets to combine)
        # Create second dataset with different sample names to avoid conflicts
        exprs_2 = rand(size_config.genes, size_config.samples)
        sample_names_2 = ["Sample2_$i" for i in 1:(size_config.samples)]
        feature_names_2 = ["Gene_$i" for i in 1:(size_config.genes)]
        sample_metadata_2 = Dict{Symbol,Vector{Any}}()
        feature_metadata_2 = Dict{Symbol,Vector{Any}}()
        experiment_data_2 = MIAME(;
                                  name="Benchmark Dataset 2",
                                  lab="Benchmark Lab",
                                  contact="benchmark@test.com",
                                  title="Performance Test Data 2",
                                  abstract="Generated data for benchmarking ExpressionData.jl",
                                  url="",
                                  pub_med_id="",
                                  samples=sample_names_2,
                                  hybridizations=String[],
                                  norm_controls=String[],
                                  preprocessing=String[],
                                  other=Dict{Symbol,String}())
        test_data_2 = ExpressionSet(exprs_2, sample_names_2, feature_names_2,
                                    sample_metadata_2, feature_metadata_2,
                                    experiment_data_2, :benchmark)

        combine_result = @benchmark ExpressionData.combine([$test_data, $test_data_2])
        combine_time = median(combine_result.times) / 1e9
        combine_memory = median(combine_result.memory)

        # println("  combine datasets: $(format_time(combine_time)) | $(format_memory(combine_memory))")

        # Store combine result
        push!(size_result["operations"],
              Dict{String,Any}("name" => "combine datasets",
                               "time" => combine_time,
                               "memory" => combine_memory))

        push!(results.data_manipulation, size_result)
        next!(progress)
    end
end

"""
Benchmark ExpressionSet creation
"""
function benchmark_creation!(results::BenchmarkResults)
    println("\n🏗️  ExpressionSet Creation Benchmark")
    println("="^50)

    progress = Progress(length(BENCHMARK_SIZES), "Creation benchmarks: ")
    for size_config in BENCHMARK_SIZES
        # println("\n$(size_config.name) Dataset ($(size_config.genes) genes × $(size_config.samples) samples):")

        # Pre-generate data to isolate construction time
        exprs = rand(size_config.genes, size_config.samples)
        sample_names = ["Sample_$i" for i in 1:(size_config.samples)]
        feature_names = ["Gene_$i" for i in 1:(size_config.genes)]
        sample_metadata = Dict{Symbol,Vector{Any}}()
        feature_metadata = Dict{Symbol,Vector{Any}}()

        experiment_data = MIAME(;
                                name="Test", lab="Lab", contact="test@test.com",
                                title="Test",
                                abstract="Test", url="", pub_med_id="",
                                samples=sample_names,
                                hybridizations=String[], norm_controls=String[],
                                preprocessing=String[], other=Dict{Symbol,String}())

        # Benchmark construction
        result = @benchmark ExpressionSet($exprs, $sample_names, $feature_names,
                                          $sample_metadata, $feature_metadata,
                                          $experiment_data, :test)
        time = median(result.times) / 1e9
        memory = median(result.memory)

        # println("  ExpressionSet creation: $(format_time(time)) | $(format_memory(memory))")

        # Benchmark random generation
        rand_result = @benchmark rand(ExpressionSet, $(size_config.genes),
                                      $(size_config.samples))
        rand_time = median(rand_result.times) / 1e9
        rand_memory = median(rand_result.memory)

        # println("  Random ExpressionSet: $(format_time(rand_time)) | $(format_memory(rand_memory))")

        # Store results
        size_result = Dict{String,Any}("size_name" => size_config.name,
                                       "genes" => size_config.genes,
                                       "samples" => size_config.samples,
                                       "creation_time" => time,
                                       "creation_memory" => memory,
                                       "random_time" => rand_time,
                                       "random_memory" => rand_memory)

        push!(results.creation, size_result)
        next!(progress)
    end
end

# parallel = true
"""
Main benchmark execution
"""
function main(output_dir::String=joinpath(@__DIR__, "results"); parallel::Bool=true)
    println("""
    Starting comprehensive benchmark suite...
    """)

    if parallel && nthreads() > 1
        println("Parallel execution: ENABLED")
    else
        println("Parallel execution: DISABLED")
    end
    println("Time: $(now())")

    # Initialize results collection
    results = BenchmarkResults()
    # Run all benchmark suites
    try
        benchmark_creation!(results)
        benchmark_data_access!(results; parallel=parallel)
        benchmark_data_manipulation!(results)
        benchmark_io_operations!(results; parallel=parallel)

        # println("\n✅ Benchmark suite completed successfully!")

        # Generate output filenames with timestamp
        timestamp = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
        human_readable_file = joinpath(output_dir,
                                       "benchmark_results_$(timestamp).txt")
        machine_readable_file = joinpath(output_dir,
                                         "benchmark_results_$(timestamp).json")

        # Save results
        println("\n📄 Saving results...")
        save_human_readable_results(results, human_readable_file)
        save_machine_readable_results(results, machine_readable_file)

        println("Human-readable results saved to: $human_readable_file")
        println("Machine-readable results saved to: $machine_readable_file")

    catch e
        println("\n❌ Benchmark failed with error: $e")
        rethrow(e)
    end
end

# Run benchmarks if this script is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    # Check if parallel execution should be disabled via command line argument
    parallel = length(ARGS) == 0 || ARGS[1] != "--sequential"
    main(; parallel=parallel)
end
