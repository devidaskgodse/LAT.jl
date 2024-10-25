using DataFrames

function file_contents(filename)
    split(read(filename, String), '\n')[1:end-1]
end

function read_log(filename)
    log_lines = file_contents(filename)
    simulation_start = findfirst(x -> occursin("Step", x), log_lines)
    simulation_end = findfirst(x -> occursin("Loop", x), log_lines)

    parsed_lines = split.(log_lines[simulation_start:simulation_end-1])
    column_headers = parsed_lines[1]
    time_series_data = Vector{Float64}[]
    for log_entry in parsed_lines[2:end]
        if tryparse(Float64, log_entry[1]) != nothing
            push!(time_series_data, parse.(Float64, log_entry))
        end
    end

    return DataFrame(mapreduce(permutedims, vcat, time_series_data), column_headers)
end

function read_dump(filename)
    dump_lines = file_contents(filename)
    timestep_markers = findall(x -> x == "ITEM: TIMESTEP", dump_lines)

    atoms_header = dump_lines[findfirst(x -> occursin("ITEM: ATOMS", x), dump_lines)]
    atom_properties = split(atoms_header, " ")[3:end]
    pushfirst!(atom_properties, "timestep")

    trajectory_data = DataFrame([name => Float64[] for name in atom_properties])

    for t in 1:length(timestep_markers)-1
        atom_lines = dump_lines[timestep_markers[t]+9:timestep_markers[t+1]-1]
        timestepped_lines = [
            dump_lines[timestep_markers[t]+1] * " " * line for line in atom_lines
        ]
        atom_coords = [
            parse.(Float64, entry) for entry in map(split, timestepped_lines)
        ]

        for atom_entry in atom_coords
            push!(trajectory_data, atom_entry)
        end
    end

    if hasproperty(trajectory_data, :timestep)
        trajectory_data.timestep = convert.(Int64, trajectory_data.timestep)
    end

    if hasproperty(trajectory_data, :id)
        trajectory_data.id = convert.(Int64, trajectory_data.id)
    end

    if hasproperty(trajectory_data, :type)
        trajectory_data.type = convert.(Int64, trajectory_data.type)
    end

    return trajectory_data
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
