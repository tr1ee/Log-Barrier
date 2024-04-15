using DataFrames, CSV, FileIO, StatsBase

setprecision(BigFloat, 256)

function minusBigFloat(a, b)
    return log(BigFloat(a)) - log(BigFloat(b))
end

function minus64(a, b)
    return log(Float64(a)) - log(Float64(b))
end

function DivideBigFloat(a, b)
    return log(BigFloat(a / b))
end

function Divide64(a, b)
    return log(Float64(a / b))
end

function truncateTo16Digits(value)
    str = string(value)
    decimalIndex = findfirst('.', str)
    if decimalIndex !== nothing
        # Ensure up to 16 digits after the decimal point are included
        # println(length(str)) Here length after decimal
        return str[1:min(end, decimalIndex + 15)]
    else
        return str
    end
end

function cutAndCompareWithGroundTruth(ground_truth, other_value)
    # Convert and truncate values to strings
    ground_truth_str = truncateTo16Digits(ground_truth)
    other_value_str = truncateTo16Digits(other_value)
    
    # Direct comparison of truncated strings
    comparison_result = ground_truth_str == other_value_str ? "No" : "Yes"
    
    return other_value_str, comparison_result
end

function runExperiment(a, b)
    test_dataframe = DataFrame(
        float_base = String[],
        approach = String[],
        a = Float64[],
        b = Float64[],
        Value = String[],
        ComparisonResult = String[]
    )

    minusBigFloat_result = minusBigFloat(a, b)
    minus64_result = minus64(a, b)
    divideBigFloat_result = DivideBigFloat(a, b)
    divide64_result = Divide64(a, b)

    minus64_str, minus_comparison = cutAndCompareWithGroundTruth(divideBigFloat_result, minus64_result)
    divide64_str, divide_comparison = cutAndCompareWithGroundTruth(divideBigFloat_result, divide64_result)
    
    push!(test_dataframe, ("BigFloat", "Minus", a, b, truncateTo16Digits(minusBigFloat_result), "N/A"))
    push!(test_dataframe, ("Float64", "Minus", a, b, minus64_str, minus_comparison))
    push!(test_dataframe, ("BigFloat", "Divide", a, b, truncateTo16Digits(divideBigFloat_result), "N/A"))
    push!(test_dataframe, ("Float64", "Divide", a, b, divide64_str, divide_comparison))    

    return test_dataframe
end

function main(a, b, csv_file)
    println(minusBigFloat(a, b))
    println(minus64(a, b))
    println(DivideBigFloat(a, b))
    println(Divide64(a, b))

    results = runExperiment(a, b)

    if isfile(csv_file)
        CSV.write(csv_file, results, append=true)
    else
        CSV.write(csv_file, results)
    end
end

# Define intervals for a and b
initial_val_a = 1e-4
increment_a = 1e-5
vec_a = [initial_val_a + i * increment_a for i in 1:10]

initial_val_b = 1e-4 + 1e-8  # Different initial value for b
increment_b = 1e-5     # Different increment for b
vec_b = [initial_val_b + i * increment_b for i in 1:10]

csv_file = "test4.csv"
for i in 1:min(length(vec_a), length(vec_b)) - 1
    a = vec_a[i]
    b = vec_b[i]
    main(a, b, csv_file)
end

#bigger range 
# rounding in Julia(Problem under Float 64)

df = CSV.read("test4.csv", DataFrame)

# Count "Yes" groups
yes_count = sum(df.ComparisonResult .== "Yes")
println("Total 'Yes' Groups: $yes_count")


# Filter to include only "Yes" outcomes
yes_df = filter(row -> row.ComparisonResult == "Yes", df)

# Assuming 'a' and 'b' are your variables of interest
# Define the range and bins for 'a'
min_a, max_a = minimum(df.a), maximum(df.a)
num_bins_a = 10  # Number of bins you want
bin_size_a = (max_a - min_a) / num_bins_a

# Function to assign bin based on value
function assign_bin(value, min_val, bin_size, num_bins)
    bin = ceil(Int, (value - min_val) / bin_size)
    return min(bin, num_bins)  # Ensure the bin is not out of range
end

# Assign bins for 'a'
a_bins = [assign_bin(val, min_a, bin_size_a, num_bins_a) for val in yes_df.a]

# Add bin information to DataFrame
yes_df[!, :a_bin] = a_bins

# Now you can group by 'a_bin' and count occurrences or perform further analysis
# For grouping and finding the bin with the highest concentration of "Yes"
grouped_df = groupby(yes_df, :a_bin)
bin_counts = combine(grouped_df, nrow => :count)
sorted_bins = sort(bin_counts, :count, rev=true)

# Find the bin with the highest count
max_bin = sorted_bins[1, :]

println("Bin with highest concentration of 'Yes': ", max_bin.a_bin)
# Translate bin number back to the interval range if needed
max_bin_range = ((max_bin.a_bin - 1) * bin_size_a + min_a, max_bin.a_bin * bin_size_a + min_a)
println("Range for this bin: ", max_bin_range)