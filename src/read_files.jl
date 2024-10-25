using DataFrames

function file_contents(filename)
    split(read(filename, String), '\n')[1:end-1]
end

function read_log(filename)
	lines = file_contents(filename)
	output_start = findfirst(x -> occursin("Step", x), lines)
	output_end = findfirst(x -> occursin("Loop", x), lines)

	split_lines = split.(lines[output_start:output_end-1])
	headers = split_lines[1]
	data = Vector{Float64}[]
	for x in split_lines[2:end]
		if tryparse(Float64, x[1]) != nothing
		    push!(data, parse.(Float64, x))
		end
	end

	return DataFrame(mapreduce(permutedims, vcat, data), headers)
end

function read_dump(filename)
	lines = file_contents(filename)
    timestep_indices = findall(x -> x == "ITEM: TIMESTEP", lines)

    line_with_columns = lines[findfirst(x -> occursin("ITEM: ATOMS", x), lines)]
    column_names = split(line_with_columns, " ")[3:end]
    pushfirst!(column_names, "timestep")

    df = DataFrame([name => Float64[] for name in column_names])

    for i in 1:length(timestep_indices)-1
        line = lines[timestep_indices[i]+9:timestep_indices[i+1]-1]
        line_with_timestep = [lines[timestep_indices[i]+1] * " " * k for k in line]
        st = [parse.(Float64, entry) for entry in map(split, line_with_timestep)]

        for k in st
            push!(df, k)
        end
    end

    if hasproperty(df, :timestep)
    	df.timestep = convert.(Int64, df.timestep)
    end

    if hasproperty(df, :id)
    	df.id = convert.(Int64, df.id)
    end

    if hasproperty(df, :type)
    	df.type = convert.(Int64, df.type)
    end

    return df
end

function read_chunk(filename)
	lines = file_contents(filename)

    headers = split(lines[3])[2:end]

    split_lines = split.(lines[5:end])
    data = map(x -> parse.(Float64, x), split_lines)

    return DataFrame(mapreduce(permutedims, vcat, data), headers)
end

export file_contents
export read_log, read_dump, read_chunk
