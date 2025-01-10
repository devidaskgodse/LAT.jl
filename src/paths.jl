function add_base_directories()
    paths = Dict{String, String}()

    paths["base"] = pwd()
    paths["janus"] = joinpath(paths["base"], ".janus")
    paths["literature"] = joinpath(paths["base"], "literature")
    paths["scripts"] = joinpath(paths["base"], "scripts")
    paths["data"] = joinpath(paths["base"], "data")
    paths["visuals"] = joinpath(paths["base"], "visuals")
    paths["reports"] = joinpath(paths["base"], "reports")
    return paths
end

function add_configs!(paths)
    paths["configs"] = joinpath(paths["janus"], "configurations.csv")
    paths["params"] = joinpath(paths["janus"], "params.yaml")
    return paths
end

function add_data_directories!(paths)
    # Data subdirectories
    for subdir in ["expt", "sims", "parsed", "processed", "modelled"]
        paths[subdir] = joinpath(paths["data"], subdir)
    end

    # Data type directories
    for dir in ["parsed", "processed", "modelled"]
        for type in ["thermo", "chunks", "dumps"]
            paths["$(dir)_$(type)"] = joinpath(paths[dir], type)
        end
    end
    return paths
end

function add_visuals_directories!(paths)
    # Visual subdirectories
    for subdir in ["schematics", "images", "plots", "movies"]
        paths[subdir] = joinpath(paths["visuals"], subdir)
    end

    # Plot format directories
    for format in ["tex", "pdf", "svg", "png"]
        paths["plots_$format"] = joinpath(paths["plots"], format)
    end

    return paths
end

function create_paths(paths)
    for (key, path) in paths
        if !ispath(path)
            mkpath(path)
        end
    end
end

function list_all_paths()
    paths = add_base_directories()
    add_configs!(paths)
    add_data_directories!(paths)
    add_visuals_directories!(paths)
    return paths
end

function create_all_paths()
    paths = list_all_paths()
    create_paths(paths)
end

export create_paths, list_all_paths, create_all_paths
