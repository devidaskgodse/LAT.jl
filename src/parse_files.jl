using DataFrames

function read_file_contents(filename)
    split(read(filename, String), '\n')[1:end-1]
end

export read_file_contents

"""
    parse_log(filename::String) -> DataFrame

Reads a log file containing step data and returns it as a `DataFrame`.

# Arguments
- `filename::String`: The name of the log file.

# Returns
- A `DataFrame` where the first row contains the headers (parsed from the log
  file) and subsequent rows contain parsed numerical data. The columns are
  labeled based on the headers.

# Details
- The function looks for the lines containing "Step" and "Loop" to identify
  the section of the file with the log data. It then parses the lines between
  these markers and returns the parsed data as a `DataFrame`.
"""
function parse_log(filename)
    log_lines = read_file_contents(filename)
    
    log_start_index = findfirst(x -> occursin("Step", x), log_lines)
    log_end_index = findfirst(x -> occursin("Loop", x), log_lines)

    parsed_lines = split.(log_lines[log_start_index:log_end_index-1])

    column_headers = parsed_lines[1]

    parsed_data = Vector{Float64}[]
    for log_entry in parsed_lines[2:end]
        if tryparse(Float64, log_entry[1]) != nothing
            push!(parsed_data, parse.(Float64, log_entry))
        end
    end

    return DataFrame(
        mapreduce(permutedims, vcat, parsed_data),
        column_headers
    )
end

"""
    parse_dump(filename::String) -> DataFrame

Reads a dump file containing timestep and atom data and returns it as a
`DataFrame`.

# Arguments
- `filename::String`: The name of the dump file.

# Returns
- A `DataFrame` where each row contains atom data associated with a particular
  timestep. The columns are based on the atom data header, with an additional
  `"timestep"` column.

# Details
- The function identifies all lines containing "ITEM: TIMESTEP" to determine
  where each timestep's data begins. It extracts atom column headers from the
  "ITEM: ATOMS" line and appends the `"timestep"` column to these headers.
- The atom data for each timestep is parsed and stored in the DataFrame.
  Certain columns (e.g., `timestep`, `id`, `type`) are converted to integers
  if they exist in the DataFrame.
"""
function parse_dump(filename)
    dump_lines = read_file_contents(filename)
    
    timestep_markers = findall(x -> x == "ITEM: TIMESTEP", dump_lines)
    atoms_header = findfirst(x -> occursin("ITEM: ATOMS", x), dump_lines)
    
    # trajectory data range: atoms_headers[index]+1:timestep_markers[index]-1
    # assuming
    # length(timestep_markers) == length(trajectory_data_starts)
    # length(timestep_markers) == length(trajectory_data_ends)
    timestep_data = timestep_markers .+ 1
    trajectory_data_starts = timestep_markers .+ 9
    trajectory_data_ends = push!(timestep_markers[2:end], length(dump_lines)+1) .-1

    column_names = split(dump_lines[atoms_header], " ")[3:end]
    pushfirst!(column_names, "timestep")

    trajectory_data = DataFrame([name => Float64[] for name in column_names])
    
    for index in 1:length(timestep_data)
        current_timestep = dump_lines[timestep_data[index]]
        trajectory_data_start = trajectory_data_starts[index]
        trajectory_data_end = trajectory_data_ends[index]
        
        current_timestep_data = current_timestep .* " " .* dump_lines[
            trajectory_data_start:trajectory_data_end
        ]

        array = map(x -> parse.(Float64, split(x)), current_timestep_data)
        map(x -> push!(trajectory_data, x), array)
    end

    return sort!(trajectory_data)
end

"""
    parse_chunk(filename::String) -> DataFrame

Reads a chunk of data from the specified file and returns it as a `DataFrame`.

# Arguments
- `filename::String`: The name of the file containing the chunk of data.

# Returns
- A `DataFrame` with parsed numerical data where the headers are cleaned by
  removing any instance of `"c_"`, `"v_"`, `"["`, or `"]"`. The first column is
  labeled `"last_timestep"`.

# Details
- The function reads in lines from the file, extracts and cleans the headers,
  and parses the data into a numerical format. The parsed data is combined
  with the timestamp (extracted from line 4) and stored in a `DataFrame`.
"""
function parse_chunk(filename)
    chunk_lines = read_file_contents(filename)
    end_timestamp = split(chunk_lines[4])[1]
    raw_headers = split(chunk_lines[3])[2:end]
    
    # A regex replace that removes any instance of the following:
    # "c_", "v_", "\[", "\]"
    cleaned_headers = replace.(raw_headers, r"c_|v_|\[|\]" => "")
    final_headers = vcat(["last_timestep"], cleaned_headers)

    parsed_rows = split.(chunk_lines[5:end])
    chunk_data = map(x -> parse.(Float64, vcat([end_timestamp],x)), parsed_rows)

    return DataFrame(mapreduce(permutedims, vcat, chunk_data), final_headers)
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

function combine_dataframes(parser_function, directory, pattern)
    matching_files = find_matching_files(directory, pattern)
    dataframes = map(parser_function, matching_files)

    return unique(reduce(vcat, dataframes))
end

function combine_dataframes(parser_function, directory, include_pattern,
    exclude_pattern)

    matching_files = find_matching_files(directory, include_pattern,
        exclude_pattern)
    dataframes = map(parser_function, matching_files)

    return unique(reduce(vcat, dataframes))
end

export combine_dataframes

function parse_logs(directory, pattern)
    combine_dataframes(parse_log, directory, pattern)
end

function parse_logs(directory, include_pattern, exclude_pattern)
    combine_dataframes(parse_log, directory, include_pattern, exclude_pattern)
end

function parse_dumps(directory, pattern)
    combine_dataframes(parse_dump, directory, pattern)
end

function parse_dumps(directory, include_pattern, exclude_pattern)
    combine_dataframes(parse_dump, directory, include_pattern, exclude_pattern)
end

function parse_chunks(directory, pattern)
    combine_dataframes(parse_chunk, directory, pattern)
end

function parse_chunks(directory, include_pattern, exclude_pattern)
    combine_dataframes(parse_chunk, directory, include_pattern, exclude_pattern)
end

export parse_logs, parse_dumps, parse_chunks
