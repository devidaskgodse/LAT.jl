using DataFrames, PGFPlotsX

push!(PGFPlotsX.CUSTOM_PREAMBLE,
    raw"""
    \usepgfplotslibrary{fillbetween}
    \usepackage{xcolor}
    \definecolor{black}{HTML}{000000}
    \definecolor{dgray}{HTML}{9F9F9F}
    \definecolor{lgray}{HTML}{E7E7E7}
    \definecolor{red}{HTML}{D8232A}
    \definecolor{orange}{HTML}{FE8F60}
    \definecolor{yellow}{HTML}{F5BC65}
    \definecolor{blue}{HTML}{00A3DA}
    \definecolor{green}{HTML}{009848}
    \definecolor{violet}{HTML}{954F71}
    """
)

# export PGFPlotsX.CUSTOM_PREAMBLE

"""
    generate_coordinates(df::DataFrame, x_col::Symbol, y_col::Symbol; x_error=nothing, y_error=nothing)

Generate a Coordinates object from DataFrame columns for plotting purposes.

# Arguments
- `df::DataFrame`: Input DataFrame containing the data
- `x_col::Symbol`: Column name for x-axis data
- `y_col::Symbol`: Column name for y-axis data

# Keyword Arguments
- `x_error=nothing`: Optional column name for x-axis error values
- `y_error=nothing`: Optional column name for y-axis error values

# Returns
- `Coordinates`: A Coordinates object containing the specified data and optional error values

# Examples
```julia
# Basic usage without error bars
coords = generate_coordinates(df, :x, :y)

# With x-axis error bars only
coords = generate_coordinates(df, :x, :y, x_error=:x_err)

# With y-axis error bars only
coords = generate_coordinates(df, :x, :y, y_error=:y_err)

# With both x and y error bars
coords = generate_coordinates(df, :x, :y, x_error=:x_err, y_error=:y_err)
```

The function extracts data from the specified DataFrame columns and creates a Coordinates
object suitable for plotting. Error bars can be optionally included by specifying the
corresponding column names through the x_error and y_error keyword arguments.
"""
function generate_coordinates(df::DataFrame, x_col::Symbol, y_col::Symbol;
    x_error=nothing, y_error=nothing)
    x_data = df[!, x_col]
    y_data = df[!, y_col]

    if isnothing(x_error) & isnothing(y_error)
        return Coordinates(x_data, y_data)
    elseif !isnothing(x_error) & isnothing(y_error)
        xerr_data = df[!, x_error]
        return Coordinates(x_data, y_data; xerror=xerr_data)
    elseif isnothing(x_error) & !isnothing(y_error)
        yerr_data = df[!, y_error]
        return Coordinates(x_data, y_data; yerror=yerr_data)
    else
        xerr_data = df[!, x_error]
        yerr_data = df[!, y_error]
        return Coordinates(x_data, y_data; xerror=xerr_data, yerror=yerr_data)
    end
end

"""
    plot_entry(df::DataFrame, x::Symbol, y::Symbol, mark_options::PGFPlotsX.Options; xerr=nothing, yerr=nothing)

Create a PGFPlotsX Plot object from DataFrame columns with customizable styling options.

# Arguments
- `df::DataFrame`: Input DataFrame containing the data to plot
- `x::Symbol`: Column name for x-axis data
- `y::Symbol`: Column name for y-axis data
- `mark_options::PGFPlotsX.Options`: Styling options for the plot (e.g., color, mark style, line style)

# Keyword Arguments
- `xerr=nothing`: Optional column name for x-axis error bars
- `yerr=nothing`: Optional column name for y-axis error bars

# Returns
- `Plot`: A PGFPlotsX Plot object ready for rendering

# Examples
```julia
# Basic plot without error bars
plot_entry(df, :x, :y, @pgf {color="red", mark="*"})

# Plot with y error bars
plot_entry(df, :x, :y, @pgf {color="blue", mark="square"}, yerr=:y_uncertainty)

# Plot with both x and y error bars
plot_entry(df, :x, :y, @pgf {color="green", mark="triangle"},
          xerr=:x_uncertainty, yerr=:y_uncertainty)
```

This function creates a PGFPlotsX Plot object using the specified DataFrame columns and
styling options. It supports optional error bars in both x and y directions. The function
internally uses `generate_coordinates` to process the data before creating the plot.
"""
function plot_entry(df::DataFrame, x::Symbol, y::Symbol,
    mark_options::PGFPlotsX.Options; xerr=nothing, yerr=nothing)

    if isnothing(xerr) & isnothing(yerr)
        @pgf Plot(mark_options,
            generate_coordinates(df, x, y)
        )
    elseif isnothing(xerr) & !isnothing(yerr)
        @pgf Plot(mark_options,
            generate_coordinates(df, x, y, y_error=yerr)
        )
    elseif !isnothing(xerr) & isnothing(yerr)
        @pgf Plot(mark_options,
            generate_coordinates(df, x, y, x_error=xerr)
        )
    else
        @pgf Plot(mark_options,
            generate_coordinates(df, x, y, x_error=xerr, y_error=yerr)
        )
    end
end

export plot_entry

# save pgfplots in multiple formats
"""
    save_plot(plotpath, plotname, extension, plot_in_pgf)

Base function for saving PGFPlotsX plots in various formats.

# Arguments
- `plotpath`: Directory path where the plot should be saved
- `plotname`: Name of the output file (without extension)
- `extension`: File format extension (e.g., "tex", "pdf", "svg", "png")
- `plot_in_pgf`: PGFPlotsX plot object to be saved

# Notes
Uses PGFPlotsX.pgfsave internally with `include_preamble=false`
"""
function save_plot(plotpath, plotname, extension, plot_in_pgf)
    pgfsave(joinpath(plotpath, "$plotname.$extension"),
        plot_in_pgf,
        include_preamble=false
    )
end

"""
    save_tex(plotpath, plotname, plot_in_pgf)

Save a PGFPlotsX plot as a TEX file.

# Arguments
- `plotpath`: Directory path where the plot should be saved
- `plotname`: Name of the output file (without extension)
- `plot_in_pgf`: PGFPlotsX plot object to be saved

# Output
Saves the plot as `plotname.tex` in the specified directory
"""
function save_tex(plotpath, plotname, plot_in_pgf)
    save_plot(plotpath, plotname, "tex", plot_in_pgf)
end

"""
    save_pdf(plotpath, plotname, plot_in_pgf)

Save a PGFPlotsX plot as a PDF file.

# Arguments
- `plotpath`: Directory path where the plot should be saved
- `plotname`: Name of the output file (without extension)
- `plot_in_pgf`: PGFPlotsX plot object to be saved

# Output
Saves the plot as `plotname.pdf` in the specified directory
"""
function save_pdf(plotpath, plotname, plot_in_pgf)
    save_plot(plotpath, plotname, "pdf", plot_in_pgf)
end

"""
    save_svg(plotpath, plotname, plot_in_pgf)

Save a PGFPlotsX plot as an SVG file.

# Arguments
- `plotpath`: Directory path where the plot should be saved
- `plotname`: Name of the output file (without extension)
- `plot_in_pgf`: PGFPlotsX plot object to be saved

# Output
Saves the plot as `plotname.svg` in the specified directory
"""
function save_svg(plotpath, plotname, plot_in_pgf)
    save_plot(plotpath, plotname, "svg", plot_in_pgf)
end

"""
    save_png(plotpath, plotname, plot_in_pgf)

Save a PGFPlotsX plot as a PNG file with high resolution (600 DPI).

# Arguments
- `plotpath`: Directory path where the plot should be saved
- `plotname`: Name of the output file (without extension)
- `plot_in_pgf`: PGFPlotsX plot object to be saved

# Output
Saves the plot as `plotname.png` in the specified directory at 600 DPI

# Notes
Unlike other save functions, this uses specific PNG settings including high DPI
for better quality output.
"""
function save_png(plotpath, plotname, plot_in_pgf)
    # save_plot(plotpath, plotname, "png", plot_in_pgf)
    pgfsave(joinpath(plotpath, "$plotname.png"),
        plot_in_pgf,
        include_preamble=false,
        dpi=600
    )
end

export save_plot, save_tex, save_pdf, save_png, save_svg
