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
function save_plot(plotpath, plotname, extension, plot_in_pgf)
    pgfsave(joinpath(plotpath, "$plotname.$extension"),
        plot_in_pgf,
        include_preamble=false
    )
end

function save_tex(plotpath, plotname, plot_in_pgf)
    save_plot(plotpath, plotname, "tex", plot_in_pgf)
end

function save_pdf(plotpath, plotname, plot_in_pgf)
    save_plot(plotpath, plotname, "pdf", plot_in_pgf)
end

function save_svg(plotpath, plotname, plot_in_pgf)
    save_plot(plotpath, plotname, "svg", plot_in_pgf)
end

function save_png(plotpath, plotname, plot_in_pgf)
    # save_plot(plotpath, plotname, "png", plot_in_pgf)
    pgfsave(joinpath(plotpath, "$plotname.png"),
        plot_in_pgf,
        include_preamble=false,
        dpi=600
    )
end

export save_plot, save_tex, save_pdf, save_png, save_svg
