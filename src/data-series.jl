# This file is part of the QuickCharts.jl package. It is licensed under the MIT License.

const _line_style_list = [:none, :solid, :dot, :dash, :dashdot]
const _mark_list = [:none, :circle, :square, :triangle, :utriangle, :cross, :xcross, :diamond, :pentagon, :hexagon, :star, :hatch, :hash]
const _tag_anchor_list = [:top, :top_right, :right, :bottom_right, :bottom, :bottom_left, :left, :top_left]


"""
    DataSeries

Abstract supertype for chart series.
"""
abstract type DataSeries end


"""
    LineSeries(X::AbstractVector, Y::AbstractVector; kwargs...)

Store the data and styling for a line-like chart series.

`X` and `Y` must have equal length. Most users should create series with
[`add_line`](@ref) or [`add_scatter`](@ref), because those helpers also attach
the series to a chart and resolve `color=:auto` against the chart palette.

# Keyword options
- `line_style`: one of `:none`, `:solid`, `:dot`, `:dash`, or `:dashdot`.
- `dash`: custom dash pattern; when nonempty, `line_style` becomes `:dash`.
- `color`: series color, or `:auto` for later chart palette assignment.
- `line_width`: positive stroke width.
- `mark`: one of the supported marker symbols.
- `mark_size`: positive marker size.
- `mark_color`, `mark_stroke_color`: marker fill and edge colors, or `:auto`.
- `label`: legend label; an empty label keeps the series out of the legend.
- `tag`, `tag_anchor`, `tag_pos`, `tag_orientation`, `tag_padding`, `tag_font_size`: on-series tag text and placement.
- `order`: nonnegative draw order; `0` is assigned by [`add_series`](@ref).
"""
mutable struct LineSeries <: DataSeries
    X                ::AbstractVector
    Y                ::AbstractVector
    line_style       ::Symbol
    line_width       ::Float64
    color            ::Union{Symbol,Color}
    dash             ::Vector{Float64}
    mark             ::Symbol
    mark_size        ::Float64
    mark_color       ::Union{Symbol,Color}
    mark_stroke_color::Union{Symbol,Color}
    label            ::AbstractString
    tag              ::AbstractString
    tag_anchor       ::Symbol
    tag_pos          ::Float64
    tag_orientation  ::Symbol
    tag_padding      ::Union{Nothing,Float64}
    tag_font_size    ::Union{Nothing,Float64}
    order            ::Int

    function LineSeries(
        X::AbstractVector,
        Y::AbstractVector;
        line_style=:solid,
        line_width=0.5,
        color=:auto,
        dash=Float64[],
        mark=:none,
        mark_size=2.5,
        mark_color=:white,
        mark_stroke_color=:auto,
        label="",
        tag="",
        tag_anchor=:top,
        tag_pos=0.5,
        tag_orientation=:horizontal,
        tag_padding::Union{Nothing,Real}=nothing,
        tag_font_size::Union{Nothing,Real}=nothing,
        order=0,
    )
        length(X) == length(Y) || throw(ArgumentError("Length of X and Y arrays must be equal"))
        line_style in _line_style_list || throw(ArgumentError("Invalid line style: $(repr(line_style))"))
        mark in _mark_list || throw(ArgumentError("Invalid mark shape: $(repr(mark))"))
        tag_anchor in _tag_anchor_list || throw(ArgumentError("Invalid tag anchor: $(repr(tag_anchor))"))
        tag_orientation in [:horizontal, :vertical, :parallel] || throw(ArgumentError("Invalid tag orientation: $(repr(tag_orientation))"))
        tag_padding === nothing || tag_padding >= 0 || throw(ArgumentError("Tag padding must be non-negative"))
        tag_font_size === nothing || tag_font_size > 0 || throw(ArgumentError("Tag font size must be positive"))
        line_width > 0 || throw(ArgumentError("Line width must be greater than zero"))
        mark_size > 0 || throw(ArgumentError("Mark size must be greater than zero"))

        color = color === :auto ? color : resolve_color(color)
        mark_color = mark_color === :auto ? mark_color : resolve_color(mark_color)
        mark_stroke_color = mark_stroke_color === :auto ? mark_stroke_color : resolve_color(mark_stroke_color)

        n = min(length(X), length(Y))

        if length(dash)==0
            if line_style==:dash
                dash = [4.0, 2.4]*line_width
            elseif line_style==:dashdot
                dash = [2.0, 1.0, 2.0, 1.0]*line_width
            elseif line_style==:dot
                dash = [1.0, 1.0]*line_width
            end
        else
            line_style = :dash
        end

        return new(
            X[1:n],
            Y[1:n],
            line_style,
            line_width,
            color,
            dash,
            mark,
            mark_size,
            mark_color,
            mark_stroke_color,
            label,
            tag,
            tag_anchor,
            tag_pos,
            tag_orientation,
            tag_padding === nothing ? nothing : float(tag_padding),
            tag_font_size === nothing ? nothing : float(tag_font_size),
            order,
        )
    end
end


"""
    BarSeries(X::AbstractVector, Y::AbstractVector; kwargs...)

Store the data and styling for a bar chart series.

`X` and `Y` must have equal length. Most users should create series with
[`add_bar`](@ref), because that helper also attaches the series to a chart and
resolves `color=:auto` against the chart palette.

# Keyword options
- `color`: series fill color, or `:auto` for later chart palette assignment.
- `line_width`: positive bar outline stroke width.
- `label`: legend label; an empty label keeps the series out of the legend.
- `bar_width`: bar width in x-data units (`0` enables auto width).
- `bar_base`: bar baseline in y-data units.
- `order`: nonnegative draw order; `0` is assigned by [`add_series`](@ref).
"""
mutable struct BarSeries <: DataSeries
    X         ::AbstractVector
    Y         ::AbstractVector
    color     ::Union{Symbol,Color}
    line_width::Float64
    label     ::AbstractString
    bar_width ::Float64
    bar_base  ::Float64
    order     ::Int

    function BarSeries(
        X::AbstractVector,
        Y::AbstractVector;
        color=:auto,
        line_width=0.5,
        label="",
        bar_width=0.0,
        bar_base=0.0,
        order=0,
    )
        length(X) == length(Y) || throw(ArgumentError("Length of X and Y arrays must be equal"))
        line_width > 0 || throw(ArgumentError("Line width must be greater than zero"))
        bar_width >= 0 || throw(ArgumentError("Bar width must be non-negative"))

        color = color === :auto ? color : resolve_color(color)
        n = min(length(X), length(Y))

        return new(X[1:n], Y[1:n], color, line_width, label, bar_width, bar_base, order)
    end
end


"""
    QuiverSeries(X::AbstractVector, Y::AbstractVector, U::AbstractVector, V::AbstractVector; kwargs...)

Store the data and styling for a quiver/vector-field chart series.

`X`, `Y`, `U`, and `V` must have equal length. Most users should create quiver
series with [`add_quiver`](@ref), which also supports rectilinear grid inputs.

# Keyword options
- `color`: arrow color. `:auto` is not supported; quiver defaults to black.
- `line_width`: positive shaft stroke width.
- `max_length`: positive maximum arrow length in screen-space points after normalization.
- `head_length`: positive requested arrowhead length in points.
- `label`: legend label; an empty label keeps the series out of the legend.
- `order`: nonnegative draw order; `0` is assigned by [`add_series`](@ref).
"""
mutable struct QuiverSeries <: DataSeries
    X         ::AbstractVector
    Y         ::AbstractVector
    U         ::AbstractVector
    V         ::AbstractVector
    color     ::Color
    line_width::Float64
    max_length::Float64
    head_length::Float64
    label     ::AbstractString
    order     ::Int

    function QuiverSeries(
        X::AbstractVector,
        Y::AbstractVector,
        U::AbstractVector,
        V::AbstractVector;
        color::Union{Symbol,Color,Tuple}=:black,
        line_width::Real=0.5,
        max_length::Real=12.0,
        head_length::Real=4.0,
        label::AbstractString="",
        order=0,
    )
        length(X) == length(Y) == length(U) == length(V) || throw(ArgumentError("Length of X, Y, U, and V arrays must be equal"))
        line_width > 0 || throw(ArgumentError("Line width must be greater than zero"))
        max_length > 0 || throw(ArgumentError("Maximum arrow length must be greater than zero"))
        head_length > 0 || throw(ArgumentError("Arrow head length must be greater than zero"))
        color == :auto && throw(ArgumentError("QuiverSeries does not support color=:auto; use an explicit color"))

        n = length(X)
        resolved_color = resolve_color(color)

        return new(
            X[1:n],
            Y[1:n],
            U[1:n],
            V[1:n],
            resolved_color,
            float(line_width),
            float(max_length),
            float(head_length),
            label,
            order,
        )
    end
end


function draw_polygon(cc::CairoContext, x, y, n, length, color, strokecolor; angle=0, draw_stroke=true)
    Δθ = 360/n
    minθ = angle + 90
    maxθ = angle + 360 + 90

    for θ in minθ:Δθ:maxθ
        xi = x + length*cosd(θ)
        yi = y - length*sind(θ)
        if θ==angle
            move_to(cc, xi, yi)
        else
            line_to(cc, xi, yi)
        end
    end

    close_path(cc)
    set_source_rgb(cc, rgb(color)...)
    if draw_stroke
        fill_preserve(cc)
        set_source_rgb(cc, rgb(strokecolor)...)
        stroke(cc)
    else
        fill(cc)
    end
end


function draw_star(cc::CairoContext, x, y, n, length, color, strokecolor; angle=0, draw_stroke=true)
    Δθ = 360/n/2
    minθ = angle + 90
    maxθ = angle + 360 + 90


    for (i,θ) in enumerate(minθ:Δθ:maxθ)
        if i%2==1
            xi = x + length*cosd(θ)
            yi = y - length*sind(θ)
        else
            xi = x + 0.5*length*cosd(θ)
            yi = y - 0.5*length*sind(θ)
        end
        if θ==angle
            move_to(cc, xi, yi)
        else
            line_to(cc, xi, yi)
        end
    end

    close_path(cc)
    set_source_rgb(cc, rgb(color)...)
    if draw_stroke
        fill_preserve(cc)
        set_source_rgb(cc, rgb(strokecolor)...)
        stroke(cc)
    else
        fill(cc)
    end
end


function draw_mark(cc::CairoContext, x, y, mark, size, color, strokecolor; draw_stroke=true)
    radius = size/2
    new_path(cc)

    if mark==:circle
        arc(cc, x, y, radius, 0, 2*pi)
        set_source_rgb(cc, rgb(color)...)
        if draw_stroke
            fill_preserve(cc)
            set_source_rgb(cc, rgb(strokecolor)...)
            stroke(cc)
        else
            fill(cc)
        end
    elseif mark==:square
        draw_polygon(cc, x, y, 4, 1.2*radius, color, strokecolor, angle=45, draw_stroke=draw_stroke)
    elseif mark==:diamond
        draw_polygon(cc, x, y, 4, 1.2*radius, color, strokecolor, angle=0, draw_stroke=draw_stroke)
    elseif mark==:triangle
        draw_polygon(cc, x, y, 3, 1.3*radius, color, strokecolor, angle=0, draw_stroke=draw_stroke)
    elseif mark==:utriangle
        draw_polygon(cc, x, y, 3, 1.3*radius, color, strokecolor, angle=180, draw_stroke=draw_stroke)
    elseif mark==:pentagon
        draw_polygon(cc, x, y, 5, 1.1*radius, color, strokecolor, angle=0, draw_stroke=draw_stroke)
    elseif mark==:hexagon
        draw_polygon(cc, x, y, 6, 1.1*radius, color, strokecolor, angle=0, draw_stroke=draw_stroke)
    elseif mark==:star
        draw_star(cc, x, y, 5, 1.25*radius, color, strokecolor, angle=0, draw_stroke=draw_stroke)
    elseif mark==:cross
        radius = 1.35*radius
        set_source_rgb(cc, rgb(strokecolor)...)
        set_line_width(cc, radius/3)
        move_to(cc, x, y-radius)
        line_to(cc, x, y+radius)
        stroke(cc)
        move_to(cc, x-radius, y)
        line_to(cc, x+radius, y)
        stroke(cc)
    elseif mark==:xcross
        radius = 1.35*radius
        set_source_rgb(cc, rgb(strokecolor)...)
        set_line_width(cc, radius/3)
        move_to(cc, x-radius, y-radius)
        line_to(cc, x+radius, y+radius)
        stroke(cc)
        move_to(cc, x+radius, y-radius)
        line_to(cc, x-radius, y+radius)
        stroke(cc)
    elseif mark==:hatch
        radius = 1.15*radius
        gap = 0.45*radius
        set_source_rgb(cc, rgb(strokecolor)...)
        set_line_width(cc, radius/4)
        for offset in (-gap, 0.0, gap)
            move_to(cc, x-radius, y+radius+offset)
            line_to(cc, x+radius, y-radius+offset)
            stroke(cc)
        end
    elseif mark==:hash
        radius = 1.10*radius
        gap = 0.45*radius
        set_source_rgb(cc, rgb(strokecolor)...)
        set_line_width(cc, radius/4)
        for offset in (-gap, gap)
            move_to(cc, x+offset, y-radius)
            line_to(cc, x+offset, y+radius)
            stroke(cc)
            move_to(cc, x-radius, y+offset)
            line_to(cc, x+radius, y+offset)
            stroke(cc)
        end
    end
end
