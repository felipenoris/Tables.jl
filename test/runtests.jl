
# Basic Table tests

using Tables
using Base.Test
using NullableArrays
using DataFrames
using Lifting

y = Tables._create_table_column(Nullable{Int}, 2)
@test typeof(y) == NullableArrays.NullableArray{Int,1}
@test length(y) == 2
@test isnull(y[2])

z = Tables._create_table_column(String, 2)
@test typeof(z) == Array{String, 1}
@test length(z) == 2

col_names = [:C_STRING, :C_INT, :C_FLOAT, :C_NSTRING, :C_NINT, :C_NFLOAT]
col_types = [String, Int, Float64, Nullable{String}, Nullable{Int}, Nullable{Float64}]
ta_schema = Tables.Schema(col_names, col_types)
rows = 2
ta = Tables.Table(ta_schema, rows)
@test size(ta) == (2,6)
@test typeof(ta[:C_STRING]) == Vector{String}
@test typeof(ta[:C_INT]) == Vector{Int}
@test typeof(ta[:C_FLOAT]) == Vector{Float64}
@test typeof(ta[:C_NSTRING]) == NullableVector{String}
@test typeof(ta[:C_NINT]) == NullableVector{Int}
@test typeof(ta[:C_NFLOAT]) == NullableVector{Float64}
ta[1,1] = "1,1"
ta[1,2] = 5
ta[1,3] = 2.2
ta[1,4] = "1;4"
ta[1,5] = 5
ta[1,6] = 2.3

ta[2,1] = "1;1"
ta[2,2] = 5
ta[2,3] = 2.2
ta[2,4] = Nullable{String}()
ta[2,5] = Nullable{Int}()
ta[2,6] = 2.3

@test ta[1,1] == "1,1"
@test ta[1,2] == 5
@test ta[1,3] == 2.2
@test lift(ta[1,4] == unlift("1;4"))
@test lift(ta[1,5] == unlift(5))
@test lift(ta[1,6] == unlift(2.3))

@test ta[2,1] == "1;1"
@test ta[2,2] == 5
@test ta[2,3] == 2.2
@test isnull(ta[2,4])
@test isnull(ta[2,5])
@test lift(ta[2,6] == unlift(2.3))

# Scalar attribution to column
@test ta[:C_STRING] == ["1,1", "1;1"]
ta[:C_STRING] = "string"
@test ta[:C_STRING] == [ "string", "string"]

# Restore original value using attribution to vector
ta[:C_STRING] = ["1,1", "1;1"]
@test ta[:C_STRING] == ["1,1", "1;1"]

# Scalar attribution to nullable column
tmp = NullableArray{String}(["1;4", Nullable{String}()])
ta[:C_NSTRING] = "10"
@test get(ta[1, :C_NSTRING] == Nullable("10"))
@test get(ta[2, :C_NSTRING] == Nullable("10"))
ta[:C_NSTRING] = Nullable{String}()
@test isnull(ta[1, :C_NSTRING])
@test isnull(ta[2, :C_NSTRING])
ta[:C_NSTRING] = tmp
@test get(ta[1, :C_NSTRING] == Nullable("1;4"))
@test isnull(ta[2, :C_NSTRING])

# Test again all table values
@test ta[1,1] == "1,1"
@test ta[1,2] == 5
@test ta[1,3] == 2.2
@test lift(ta[1,4] == unlift("1;4"))
@test lift(ta[1,5] == unlift(5))
@test lift(ta[1,6] == unlift(2.3))

@test ta[2,1] == "1;1"
@test ta[2,2] == 5
@test ta[2,3] == 2.2
@test isnull(ta[2,4])
@test isnull(ta[2,5])
@test lift(ta[2,6] == unlift(2.3))

FP_TA_CSV = joinpath(dirname(@__FILE__), "ta.csv")

try
    Tables.writecsv(FP_TA_CSV, ta)
    lines = readlines(FP_TA_CSV)
    @test length(lines) == 3
    @test chomp(lines[1]) == "C_STRING;C_INT;C_FLOAT;C_NSTRING;C_NINT;C_NFLOAT"
    @test chomp(lines[2]) == "1,1;5;2,200000000000000;\"1;4\";5;2,300000000000000"
    @test chomp(lines[3]) == "\"1;1\";5;2,200000000000000;;;2,300000000000000"

    tb = Tables.readcsv(FP_TA_CSV, col_types)
    @test names(tb) == col_names
    @test tb[1,1] == "1,1"
    @test tb[1,2] == 5
    @test tb[1,3] == 2.2
    @test lift(tb[1,4] == unlift("1;4"))
    @test lift(tb[1,5] == unlift(5))
    @test lift(tb[1,6] == unlift(2.3))
    @test tb[2,1] == "1;1"
    @test tb[2,2] == 5
    @test tb[2,3] == 2.2
    @test isnull(tb[2,4])
    @test isnull(tb[2,5])
    @test lift(tb[2,6] == unlift(2.3))

    Tables.writecsv(FP_TA_CSV, ta; decimal_separator='.', header=false)
    lines = readlines(FP_TA_CSV)
    @test length(lines) == 2
    @test chomp(lines[1]) == "1,1;5;2.200000000000000;\"1;4\";5;2.300000000000000"
    @test chomp(lines[2]) == "\"1;1\";5;2.200000000000000;;;2.300000000000000"

    tb = Tables.readcsv(FP_TA_CSV, ta_schema; decimal_separator='.', header=false)
    @test names(tb) == col_names
    @test tb[1,1] == "1,1"
    @test tb[1,2] == 5
    @test tb[1,3] == 2.2
    @test lift(tb[1,4] == unlift("1;4"))
    @test lift(tb[1,5] == unlift(5))
    @test lift(tb[1,6] == unlift(2.3))
    @test tb[2,1] == "1;1"
    @test tb[2,2] == 5
    @test tb[2,3] == 2.2
    @test isnull(tb[2,4])
    @test isnull(tb[2,5])
    @test lift(tb[2,6] == unlift(2.3))
finally
    rm(FP_TA_CSV)
end

# Table tests with thousands_separator
tb_example_csv = Tables.readcsv("example.csv", [String, Int, Float64], thousands_separator=Nullable('.'))

#=
str1;10;10.000,23
str2;-20;200,23
str3;0;20.200.100,00
str4;1.000;1000
str5;1.000.000;1.000
str6;1;1000,00
=#

@test tb_example_csv[1,1] == "str1"
@test tb_example_csv[1,2] == 10
@test tb_example_csv[1,3] == 10000.23

@test tb_example_csv[2,1] == "str2"
@test tb_example_csv[2,2] == -20
@test tb_example_csv[2,3] == 200.23

@test tb_example_csv[3,1] == "str3"
@test tb_example_csv[3,2] == 0
@test tb_example_csv[3,3] == 20200100.0

@test tb_example_csv[4,1] == "str4"
@test tb_example_csv[4,2] == 1000
@test tb_example_csv[4,3] == 1000.0

@test tb_example_csv[5,1] == "str5"
@test tb_example_csv[5,2] == 1000000
@test tb_example_csv[5,3] == 1000.0

@test tb_example_csv[6,1] == "str6"
@test tb_example_csv[6,2] == 1
@test tb_example_csv[6,3] == 1000.0

# eachrow
sch = Tables.Schema([:a, :b, :c, :d], [Int, String, Bool, Nullable{Int}])
tb = Tables.Table(sch, 3)
tb[:a] = [1, 2, 3]
tb[:b] = ["1", "2", "3"]
tb[:c] = [false, true, false]
tb[:d] = NullableArray([1, 2, Nullable{Int}()])

names!(tb, [:a, :b, :c, :d])
@test tb[1, 1] == 1
@test tb[1, 2] == "1"
@test tb[1, 3] == false
@test isnull(tb[3, 4])
@test get(tb[1, 4]) == 1

single_row = [4, "4", true, Nullable(10)]
tb = [ tb ; single_row ]

two_rows = [ 5 "5" true Nullable(2);
             6 "6" false Nullable{Int}() ]

tb = [ tb ; two_rows ]

i = 1
for r in Tables.eachrow(tb)
    @test r[:a] == i
    @test r[:b] == string(i)
    i = i + 1
end

tb2 = copy(tb)
@assert isequal(tb2, tb)

# Table with DataFrame
df = DataFrame(a = @data([1, NA]), b = [:a, :b])
df_types = [ Nullable{Int}, Nullable{Symbol} ]
df_schema = Tables.Schema([:col1, :col2], df_types)
df_table = Tables.Table(df_schema, df)
@test isnull(df_table[2,1]) == true
@test get(df_table[1,1]) == 1
@test get(df_table[1,2]) == :a
@test get(df_table[2,2]) == :b

sch = Schema( [:a => String, :b => Int, :c => String] )
tb = Tables.Table(sch, 5)
tb[:a] = "fixed-"

i = 1
for r in Tables.eachrow(tb)
    r[:c] = string(i)
    i += 1
end

tb[:d] = tb[:a] .* tb[:c]

@test tb[:d] == [ "fixed-1", "fixed-2", "fixed-3", "fixed-4", "fixed-5"]
@test tb[:a] == fill("fixed-", 5)
@test tb[:c] == [ "1", "2", "3", "4", "5"]
@test tb[:b] == fill(0, 5)

sa = Schema( [:a => String, :b => Int, :c => String] )
sb = Schema( [:a => String, :b => Int, :c => String] )
@test sa == sb

schema = Schema( [:col_a => Int, :col_b => Float64])
tb = Table(schema, 2)
tb[:col_a] = [1, 2]
tb[:col_b] = [1., 2.]
tb[:col_c] = [2, 3]
x = [ 1, 1.2, 1]
tb = [ tb ; x]
@test tb[3,3] == 1

y = [ 1 2 3 ; 4 5.5 6]
tb = [tb ; y]
@test tb[5,3] == 6
