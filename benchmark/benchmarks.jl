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

# Set random seed for reproducible benchmarks
Random.seed!(42)

println("🚀 ExpressionData.jl Benchmark Suite")
println("=====================================")

# Define benchmark data sizes
const BENCHMARK_SIZES = [(name="Small", genes=100, samples=10),
                         (name="Medium", genes=1000, samples=100),
                         (name="Large", genes=10000, samples=1000)]

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
        hostname = try
            strip(read(`hostname`, String))
        catch
            "unknown"
        end

        metadata = Dict{String,Any}("julia_version" => string(VERSION),
                                    "threads" => Threads.nthreads(),
                                    "timestamp" => string(now()),
                                    "hostname" => hostname)
        return new(metadata, [], [], [], [])
    end
end

"""
    create_test_data(n_genes::Int, n_samples::Int) -> ExpressionSet

Create test ExpressionSet with specified dimensions.
"""
function create_test_data(n_genes::Int, n_samples::Int)
    exprs = rand(n_genes, n_samples)
    phenotype_data = DataFrame(; sample_names=["Sample_$i" for i in 1:n_samples])
    feature_data = DataFrame(; feature_names=["Gene_$i" for i in 1:n_genes])

    experiment_data = MIAME(;
                            name="Benchmark Dataset",
                            lab="Benchmark Lab",
                            contact="benchmark@test.com",
                            title="Performance Test Data",
                            abstract="Generated data for benchmarking ExpressionData.jl",
                            url="",
                            pub_med_id="",
                            samples=["Sample_$i" for i in 1:n_samples],
                            hybridizations=String[],
                            norm_controls=String[],
                            preprocessing=String[],
                            other=Dict{Symbol,String}())

    return ExpressionSet(exprs, phenotype_data, feature_data, experiment_data, :benchmark)
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
    save_human_readable_results(results::BenchmarkResults, filename::String)

Save benchmark results in a human-readable format.
"""
function save_human_readable_results(results::BenchmarkResults, filename::String)
    open(filename, "w") do io
        println(io, "🚀 ExpressionData.jl Benchmark Results")
        println(io, "="^50)
        println(io, "Julia version: $(results.metadata["julia_version"])")
        println(io, "Threads: $(results.metadata["threads"])")
        println(io, "Hostname: $(results.metadata["hostname"])")
        println(io, "Timestamp: $(results.metadata["timestamp"])")
        println(io)

        # Creation benchmarks
        println(io, "🏗️  ExpressionSet Creation Benchmark")
        println(io, "="^50)
        for result in results.creation
            println(io,
                    "\n$(result["size_name"]) Dataset ($(result["genes"]) genes × $(result["samples"]) samples):")
            println(io,
                    "  ExpressionSet creation: $(format_time(result["creation_time"])) | $(format_memory(result["creation_memory"]))")
            println(io,
                    "  Random ExpressionSet: $(format_time(result["random_time"])) | $(format_memory(result["random_memory"]))")
        end

        # Data access benchmarks
        println(io, "\n🔍 Data Access Operations Benchmark")
        println(io, "="^50)
        for result in results.data_access
            println(io,
                    "\n$(result["size_name"]) Dataset ($(result["genes"]) genes × $(result["samples"]) samples):")
            for op in result["operations"]
                println(io,
                        "  $(op["name"]): $(format_time(op["time"])) | $(format_memory(op["memory"]))")
            end
        end

        # Data manipulation benchmarks
        println(io, "\n🔧 Data Manipulation Operations Benchmark")
        println(io, "="^50)
        for result in results.data_manipulation
            println(io,
                    "\n$(result["size_name"]) Dataset ($(result["genes"]) genes × $(result["samples"]) samples):")
            for op in result["operations"]
                println(io,
                        "  $(op["name"]): $(format_time(op["time"])) | $(format_memory(op["memory"]))")
            end
        end

        # I/O operations benchmarks
        println(io, "\n📁 I/O Operations Benchmark")
        println(io, "="^50)
        for result in results.io_operations
            println(io,
                    "\n$(result["size_name"]) Dataset ($(result["genes"]) genes × $(result["samples"]) samples):")
            for format_result in result["formats"]
                println(io, "  $(format_result["format_name"]) Format:")
                if haskey(format_result, "error")
                    println(io, "    ❌ Error: $(format_result["error"])")
                else
                    println(io,
                            "    Save: $(format_time(format_result["save_time"])) | $(format_memory(format_result["save_memory"]))")
                    println(io,
                            "    Load: $(format_time(format_result["load_time"])) | $(format_memory(format_result["load_memory"]))")
                    println(io,
                            "    File size: $(format_memory(format_result["file_size"]))")
                end
            end
        end
    end
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
Benchmark I/O operations across different file formats
"""
function benchmark_io_operations!(results::BenchmarkResults)
    println("\n📁 I/O Operations Benchmark")
    println("="^50)

    for size_config in BENCHMARK_SIZES
        println("\n$(size_config.name) Dataset ($(size_config.genes) genes × $(size_config.samples) samples):")

        # Create test data
        test_data = create_test_data(size_config.genes, size_config.samples)

        # Initialize result structure for this size
        size_result = Dict{String,Any}("size_name" => size_config.name,
                                       "genes" => size_config.genes,
                                       "samples" => size_config.samples,
                                       "formats" => [])

        for format in FILE_FORMATS
            println("  $(format.name) Format:")

            # Create temporary file
            temp_file = tempname() * format.ext
            format_result = Dict{String,Any}("format_name" => format.name)

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

                println("    Save: $(format_time(save_time)) | $(format_memory(save_memory))")
                println("    Load: $(format_time(load_time)) | $(format_memory(load_memory))")

                # Get file size
                file_size = filesize(temp_file)
                println("    File size: $(format_memory(file_size))")

                # Store results
                format_result["save_time"] = save_time
                format_result["save_memory"] = save_memory
                format_result["load_time"] = load_time
                format_result["load_memory"] = load_memory
                format_result["file_size"] = file_size

            catch e
                println("    ❌ Error: $e")
                format_result["error"] = string(e)
            finally
                rm(temp_file; force=true)
            end

            push!(size_result["formats"], format_result)
        end

        push!(results.io_operations, size_result)
    end
end

"""
Benchmark data access operations
"""
function benchmark_data_access!(results::BenchmarkResults)
    println("\n🔍 Data Access Operations Benchmark")
    println("="^50)

    for size_config in BENCHMARK_SIZES
        println("\n$(size_config.name) Dataset ($(size_config.genes) genes × $(size_config.samples) samples):")

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

        for (op_name, op_func) in operations
            result = @benchmark $op_func()
            time = median(result.times) / 1e9
            memory = median(result.memory)

            println("  $op_name: $(format_time(time)) | $(format_memory(memory))")

            # Store result
            push!(size_result["operations"],
                  Dict{String,Any}("name" => op_name,
                                   "time" => time,
                                   "memory" => memory))
        end

        push!(results.data_access, size_result)
    end
end

"""
Benchmark data manipulation operations
"""
function benchmark_data_manipulation!(results::BenchmarkResults)
    println("\n🔧 Data Manipulation Operations Benchmark")
    println("="^50)

    for size_config in BENCHMARK_SIZES
        println("\n$(size_config.name) Dataset ($(size_config.genes) genes × $(size_config.samples) samples):")

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

            println("  $op_name: $(format_time(time)) | $(format_memory(memory))")

            # Store result
            push!(size_result["operations"],
                  Dict{String,Any}("name" => op_name,
                                   "time" => time,
                                   "memory" => memory))
        end

        # Benchmark combine operation (create two datasets to combine)
        test_data_2 = create_test_data(size_config.genes, size_config.samples)
        # Change sample names to avoid conflicts
        test_data_2.phenotype_data.sample_names = ["Sample2_$i"
                                                   for i in 1:(size_config.samples)]

        combine_result = @benchmark ExpressionData.combine([$test_data, $test_data_2])
        combine_time = median(combine_result.times) / 1e9
        combine_memory = median(combine_result.memory)

        println("  combine datasets: $(format_time(combine_time)) | $(format_memory(combine_memory))")

        # Store combine result
        push!(size_result["operations"],
              Dict{String,Any}("name" => "combine datasets",
                               "time" => combine_time,
                               "memory" => combine_memory))

        push!(results.data_manipulation, size_result)
    end
end

"""
Benchmark ExpressionSet creation
"""
function benchmark_creation!(results::BenchmarkResults)
    println("\n🏗️  ExpressionSet Creation Benchmark")
    println("="^50)

    for size_config in BENCHMARK_SIZES
        println("\n$(size_config.name) Dataset ($(size_config.genes) genes × $(size_config.samples) samples):")

        # Pre-generate data to isolate construction time
        exprs = rand(size_config.genes, size_config.samples)
        phenotype_data = DataFrame(;
                                   sample_names=["Sample_$i"
                                                 for i in 1:(size_config.samples)])
        feature_data = DataFrame(; feature_names=["Gene_$i" for i in 1:(size_config.genes)])

        experiment_data = MIAME(;
                                name="Test", lab="Lab", contact="test@test.com",
                                title="Test",
                                abstract="Test", url="", pub_med_id="", samples=String[],
                                hybridizations=String[], norm_controls=String[],
                                preprocessing=String[], other=Dict{Symbol,String}())

        # Benchmark construction
        result = @benchmark ExpressionSet($exprs, $phenotype_data, $feature_data,
                                          $experiment_data, :test)
        time = median(result.times) / 1e9
        memory = median(result.memory)

        println("  ExpressionSet creation: $(format_time(time)) | $(format_memory(memory))")

        # Benchmark random generation
        rand_result = @benchmark rand(ExpressionSet, $(size_config.genes),
                                      $(size_config.samples))
        rand_time = median(rand_result.times) / 1e9
        rand_memory = median(rand_result.memory)

        println("  Random ExpressionSet: $(format_time(rand_time)) | $(format_memory(rand_memory))")

        # Store results
        size_result = Dict{String,Any}("size_name" => size_config.name,
                                       "genes" => size_config.genes,
                                       "samples" => size_config.samples,
                                       "creation_time" => time,
                                       "creation_memory" => memory,
                                       "random_time" => rand_time,
                                       "random_memory" => rand_memory)

        push!(results.creation, size_result)
    end
end

"""
Main benchmark execution
"""
function main(output_dir::String=".")
    println("Starting comprehensive benchmark suite...")
    println("Julia version: $(VERSION)")
    println("Threads: $(Threads.nthreads())")
    println("Time: $(now())")

    # Initialize results collection
    results = BenchmarkResults()

    # Run all benchmark suites
    try
        benchmark_creation!(results)
        benchmark_data_access!(results)
        benchmark_data_manipulation!(results)
        benchmark_io_operations!(results)

        println("\n✅ Benchmark suite completed successfully!")

        # Generate output filenames with timestamp
        timestamp = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
        human_readable_file = joinpath(output_dir, "benchmark_results_$(timestamp).txt")
        machine_readable_file = joinpath(output_dir, "benchmark_results_$(timestamp).json")

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
    main()
end
