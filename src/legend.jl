# This file is part of the QuickCharts.jl package. It is licensed under the MIT License.

const _legend_locations = [
    :right,
    :left,
    :top,
    :bottom,
    :top_right,
    :top_left,
    :bottom_right,
    :bottom_left,
    :outer_right,
    :outer_left,
    :outer_top,
    :outer_top_left,
    :outer_top_right,
    :outer_bottom,
    :outer_bottom_right,
    :outer_bottom_left
]


"""
    Legend(; location=:top_right, font="serif", font_size=7.0,
             background=nothing, ncols=1)

Configure a chart legend.

`location` controls where labeled series are drawn relative to the plot area.
Supported values are `:right`, `:left`, `:top`, `:bottom`, the corner variants
`:top_right`, `:top_left`, `:bottom_right`, `:bottom_left`, and the outer
variants `:outer_right`, `:outer_left`, `:outer_top`, `:outer_top_left`,
`:outer_top_right`, `:outer_bottom`, `:outer_bottom_right`, and
`:outer_bottom_left`.

`background` accepts the same color inputs as [`Color`](@ref), or `nothing` to
use the render background when available and white otherwise.
"""
mutable struct Legend<:FigureComponent
    location::Symbol
    font::String
    font_size::Float64
    background::Union{Nothing,Color}
    ncols::Int
    handle_length::Float64  # length of the line
    row_sep::Float64      # separation between labels
    col_sep::Float64      # separation between labels
    inner_pad::Float64      # padding inside the legend box
    outer_pad::Float64      # padding outside the legend box
    width::Float64          # width of the legend box
    height::Float64         # height of the legend box
    frame::Frame

    function Legend(;
        location::Symbol = :top_right,
        font::String = "serif",
        font_size::Real = 7.0,
        background=nothing,
        ncols::Int = 1,
        # title::String = ""
    )
        location in _legend_locations || throw(ArgumentError("location must be one of $(_legend_locations)"))
        font_size > 0 || throw(ArgumentError("font_size must be positive"))
        ncols > 0 || throw(ArgumentError("ncols must be positive"))

        return new(
            location,
            font,
            float(font_size),
            resolve_color(background),
            ncols,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            Frame(),
        )
    end
end
