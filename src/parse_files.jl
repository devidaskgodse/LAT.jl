using DataFrames

function read_file_contents(filename)
    split(read(filename, String), '\n')[1:end-1]
end

export read_file_contents

function parse_log(filename)
    log_lines = read_file_contents(filename)
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

    return DataFrame(
        mapreduce(permutedims, vcat, time_series_data),
        column_headers
    )
end

function parse_dump(filename)
    dump_lines = read_file_contents(filename)
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

function parse_chunk(filename)
    chunk_lines = read_file_contents(filename)
    chunk_headers = split(chunk_lines[3])[2:end]

    chunk_data_lines = split.(chunk_lines[5:end])
    chunk_values = map(x -> parse.(Float64, x), chunk_data_lines)

    return DataFrame(mapreduce(permutedims, vcat, chunk_values), chunk_headers)
end

export parse_log, parse_dump, parse_chunk

function find_matching_files(directory, pattern)
    matched_files = filter(contains(pattern), readdir(directory, join=true))

    if isempty(matched_files)
        throw("""
            No files found in '$directory' that match the input pattern $pattern
        """)
    end

    return matched_files
end

function find_matching_files(directory, include_pattern, exclude_pattern)
    matched_files = filter(contains(include_pattern), readdir(directory, join=true))
    filter!(!contains(exclude_pattern), matched_files)

    if isempty(matched_files)
        throw("""
            No files found in '$directory' that match the pattern $include_pattern
            and exclude pattern $exclude_pattern
        """)
    end

    return matched_files
end

export find_matching_files
