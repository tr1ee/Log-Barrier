using DataFrames, CSV, Printf, FileIO, Statistics

# Function to perform the specified calculations
function calculateLogsAndCompare(a_start::Float64, b_start::Float64, increment::Float64, groupSize::Int)
    sumLogA_float64, sumLogB_float64 = 0.0, 0.0
    sumLogA_bigfloat, sumLogB_bigfloat = BigFloat(0), BigFloat(0)
    sumLogRatio_float64, sumLogRatio_bigfloat = 0.0, BigFloat(0)
    
    for j in 0:(groupSize-1)
        a = BigFloat(a_start + j * increment)
        b = BigFloat(b_start + j * increment)

        # Calculate logs under Float64
        sumLogA_float64 += Float64(log(a))
        sumLogB_float64 += Float64(log(b))

        # Calculate logs under BigFloat
        sumLogA_bigfloat += log(a)
        sumLogB_bigfloat += log(b)

        # Calculate log ratios under Float64 and BigFloat
        sumLogRatio_float64 += Float64(log(a / b))
        sumLogRatio_bigfloat += log(a / b)
    end

    # Calculate the sum log differences
    sumLogDiff_float64 = sumLogA_float64 - sumLogB_float64
    sumLogDiff_bigfloat = sumLogA_bigfloat - sumLogB_bigfloat

    DataFrame([
        :A_Start => [a_start], 
        :B_Start => [b_start], 
        :SumLogA_Float64 => [sumLogA_float64], 
        :SumLogB_Float64 => [sumLogB_float64], 
        :SumLogA_BigFloat => [sumLogA_bigfloat], 
        :SumLogB_BigFloat => [sumLogB_bigfloat],
        :SumLogDiff_Float64 => [sumLogDiff_float64],
        :SumLogDiff_BigFloat => [sumLogDiff_bigfloat],
        :SumLogRatio_Float64 => [sumLogRatio_float64],
        :SumLogRatio_BigFloat => [sumLogRatio_bigfloat]
    ])
end

# Function to write results to a CSV file
function writeToCSV(df::DataFrame, filename::String)
    CSV.write(filename, df)
    println("Results written to $filename")
end

# Function to compare outcomes (separated from CSV writing for clarity)
function compareOutcomes(df::DataFrame)
    for row in eachrow(df)
        ground_truth = row[:SumLogRatio_BigFloat]
        float64_diff = row[:SumLogDiff_Float64]
        float64_ratio = row[:SumLogRatio_Float64]
        
        # Print differences between Float64 results and the BigFloat ground truth
        println("Comparing outcomes against ground truth (BigFloat sum log(a/b)) for A_Start = ", row[:A_Start])
        println("Difference (Float64 sum log(a) - sum log(b) vs. Ground Truth): ", (abs(BigFloat(float64_diff) - ground_truth))/ground_truth)
        println("Difference (Float64 sum log(a/b) vs. Ground Truth): ", (abs(BigFloat(float64_ratio) - ground_truth))/ground_truth)
    end
end

# Function to run calculations for multiple groups, compare outcomes, and write to CSV
function runMultipleGroupsAndCompare(a_starts::Array{Float64}, increment::Float64, groupSize::Int, filename::String)
    all_results = DataFrame()

    for a_start in a_starts
        b_start = a_start + 1e-8  # Ensure b starts slightly different from a
        group_results = calculateLogsAndCompare(a_start, b_start, increment, groupSize)
        all_results = vcat(all_results, group_results)
    end

    # Separately compare outcomes and then write to CSV
    compareOutcomes(all_results)
    writeToCSV(all_results, filename)
end

a_starts = [1e-10,100,1000,10000,100000,1000000]
increment = 1e-4
groupSize = 1000000
filename = "calculation_results group size 1000000.csv"

# Run the process
runMultipleGroupsAndCompare(a_starts, increment, groupSize, filename)
