using DataFrames, FileIO, Statistics

function calculateDiff(a::Float64, b::Float64)

    substract = log(a - b) - log(a)

    add = log(a + b) - log(a)

    results = substract + add

    print("the result is", results)
end

a = 1.000
b = 1e-4

calculateDiff(a,b)
