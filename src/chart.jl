# This file is part of the QuickCharts.jl package. It is licensed under the MIT License.

"""
    Chart(;
        size=(8cm, 5cm), font="NewComputerModern", font_size=10.0,
        xlimits, ylimits, aspect_ratio=:auto,
        nxticks=:auto, nyticks=:auto,
        title="", background=nothing,
        xlabel="`x`", ylabel="`y`",
        xticks=Float64[], yticks=Float64[],
        xtick_labels=String[], ytick_labels=String[],
        legend=:top_right, legend_font_size=0, legend_background=nothing)

Construct a 2D chart figure with axes, legend, and optional tick customization.

# Arguments
- `size::Tuple{<:Real,<:Real}`: width × height in points. Use `cm` as a convenience helper, e.g. `size=(8cm, 6cm)`.
- `font::AbstractString`: font family for axes and legend.
- `font_size::Real`: base font size.
- `xlimits::Vector{<:Real}`, `ylimits::Vector{<:Real}`: axis limits `[min,max]`; use empty vectors for auto scaling.
- `aspect_ratio::Symbol`: `:auto` or `:equal`.
- `nxticks::Union{Int,Symbol}`, `nyticks::Union{Int,Symbol}`: target number of tick
  intervals, or `:auto` to choose a nice interval count that includes both endpoints.
- `title::AbstractString`: chart title, centered above the plot area.
- `background::Union{Nothing,Symbol,Color,Tuple}`: full-figure background fill; `nothing` leaves the figure unfilled.
- `xlabel::AbstractString`, `ylabel::AbstractString`: axis labels.
- `xticks`, `yticks`: explicit tick positions; empty vectors enable auto ticks and `:none` hides ticks, tick labels, and gridlines on that axis.
- `xtick_labels::Vector{<:AbstractString}`, `ytick_labels::Vector{<:AbstractString}`: custom tick labels; if provided, lengths must match the corresponding tick arrays.
- `legend::Symbol`: legend location (e.g., `:top_right`, `:top_left`, `:bottom_left`, `:outer_right`).
- `legend_font_size::Real`: legend font size; `0` uses `font_size`.
- `legend_background::Union{Nothing,Symbol,Color,Tuple}`: legend box fill color; if unset it defaults to white standalone and follows the grid background when drawn inside a `ChartGrid`.

# Notes
- Use `add_series` to append data series to the chart.
- Use `add_contour` to append contour plots on rectilinear grids.
- Use `add_annotation` to add plot-relative overlay annotations.
- Prefer backticks for inline math in plot text, e.g. `` `sin(x)` ``. Dollar
  delimiters are also accepted, but must be escaped in Julia strings, e.g.
  `"\$sin(x)\$"`.
- The legend is drawn after annotations.
- `background=nothing` leaves the chart background unfilled in vector outputs and uses a white page background in PNG.
- Use `save` to export the chart to a file.

# Returns
- A `Chart` object.

# Example
```julia
using QuickCharts: Chart, cm

ch = Chart(size=(8cm, 6cm),
           title="Response History",
           xlabel="Time [s]",
           ylabel="Displacement [mm]",
           xlimits=[0.0,10.0],
           ylimits=[-5.0,5.0],
           legend=:bottom_right)
```
"""
mutable struct Chart <: Figure
    width::Float64
    height::Float64
    figure_frame::Frame
    background::Union{Nothing,Color}
    title_box::TextBox
    canvas::Canvas
    xaxis::Axis
    yaxis::Axis
    dataseries::Vector{DataSeries}
    legend::Legend
    annotations::AbstractArray

    aspect_ratio::Symbol
    outerpad::Float64
    left_items::Vector{FigureComponent}
    right_items::Vector{FigureComponent}
    top_items::Vector{FigureComponent}
    bottom_items::Vector{FigureComponent}
    overlay_items::Vector{FigureComponent}
    icolor::Int
    iorder::Int

    function Chart(;
        size=(8cm, 5cm),
        font="NewComputerModern",
        font_size::Real=10.0,
        xlimits=Float64[],
        ylimits=Float64[],
        aspect_ratio=:auto,
        nxticks::Union{Int,Symbol}=:auto,
        nyticks::Union{Int,Symbol}=:auto,
        title::AbstractString="",
        background::Union{Nothing,Symbol,Color,Tuple}=nothing,
        xlabel::AbstractString="`x`",
        ylabel::AbstractString="`y`",
        xticks=Float64[],
        yticks=Float64[],
        xtick_labels::Vector{<:AbstractString}=String[],
        ytick_labels::Vector{<:AbstractString}=String[],
        legend::Symbol=:top_right,
        legend_font_size::Real=0,
        legend_background::Union{Nothing,Symbol,Color,Tuple}=nothing
    )
        if legend_font_size == 0
            legend_font_size = font_size
        end

        font_size > 0 || throw(ArgumentError("Chart: font_size must be positive"))
        legend_font_size > 0 || throw(ArgumentError("Chart: legend_font_size must be positive"))
        aspect_ratio in (:auto, :equal) || throw(ArgumentError("Chart: Invalid aspect_ratio: $aspect_ratio. Use :auto or :equal. Got $(repr(aspect_ratio))."))
        font_size = float(font_size)
        legend_font_size = float(legend_font_size)

        width, height = size
        outerpad = 0.01 * min(width, height)
        the_legend = Legend(; location=legend, font=font, font_size=legend_font_size, background=legend_background, ncols=1)
        xaxis = Axis(direction=:horizontal, limits=xlimits, label=xlabel, font=font, font_size=font_size, ticks=xticks, tick_labels=xtick_labels, nticks=nxticks)
        yaxis = Axis(direction=:vertical, limits=ylimits, label=ylabel, font=font, font_size=font_size, ticks=yticks, tick_labels=ytick_labels, nticks=nyticks)
        background = resolve_color(background)
        title_box = TextBox(title)

        this = new(width, height, Frame(0.0, 0.0, width, height), background, title_box, Canvas(), xaxis, yaxis, [], the_legend, [],
            aspect_ratio, outerpad, FigureComponent[], FigureComponent[], FigureComponent[], FigureComponent[], FigureComponent[], 1, 1)

        return this
    end
end


_figure_background(c::Chart) = c.background
_figure_renderable(c::Chart) = !isempty(c.dataseries)

function _chart_gridline_color(c::Chart, ctx::RenderContext)
    background = ctx.background === nothing ? c.background : ctx.background
    return background === nothing ? Color(0.9, 0.9, 0.9) : darken(grayscale(background), 0.15)
end

_series_uses_chart_palette(::DataSeries) = true
_series_uses_chart_palette(::ContourSeries) = false
_series_uses_chart_palette(::QuiverSeries) = false

"""
    add_series(chart::Chart, series::DataSeries)

Append an already-constructed series to `chart`.

# Arguments
- `chart::Chart` : Target chart (mutated).
- `series::DataSeries` : Series to attach.

# Notes
- `add_series` resolves `color=:auto` against the chart palette.
- `add_series` assigns an incremental draw order when `series.order == 0`.

# Returns
- The series object.

# Examples
```julia
ch = Chart(size=(300,200), xlabel="Time [s]", ylabel="Displacement [mm]",
           xlimits=[0.0,10.0], ylimits=[-5.0,5.0], legend=:bottom_right)

add_series(ch, LineSeries(0:0.1:10, sin.(0:0.1:10); label="sin"))
```
"""
function add_series(chart::Chart, series::DataSeries)
    if _series_uses_chart_palette(series) && series.color === :auto
        series.color = Color(_default_colors[chart.icolor])
        chart.icolor = mod(chart.icolor, length(_default_colors)) + 1
    end

    if series.order === 0
        series.order = chart.iorder
        chart.iorder += 1
    end

    push!(chart.dataseries, series)

    return series
end

"""
    add_line(chart::Chart, X::AbstractVector, Y::AbstractVector; kwargs...)

Add a line series to `chart`.

# Arguments
- `chart::Chart`: Target chart (mutated).
- `X, Y::AbstractVector`: Data vectors.
- `kwargs...`: Keyword arguments controlling series appearance and metadata.

# Keyword options
- `line_style::Symbol = :solid`: Line style (e.g. `:solid`, `:dash`, ...).
- `dash::Vector{Float64} = Float64[]`: Custom dash pattern. If nonempty, overrides `line_style`.
- `color::Union{Symbol,Color,Tuple} = :auto`: Line/marker color. `:auto` selects from the chart palette cyclically.
- `line_width::Float64 = 0.5`: Line width (> 0).
- `mark::Symbol = :none`: Mark shape.
- `mark_size::Float64 = 2.5`: Mark size (> 0).
- `mark_color::Union{Symbol,Color,Tuple} = :white`: Mark fill color.
- `mark_stroke_color::Union{Symbol,Color,Tuple} = :auto`: Mark edge color (`:auto` follows `color`).
- `label::AbstractString = ""`: Legend label.
- `tag::AbstractString = ""`: On-curve annotation text.
- `tag_anchor::Symbol = :top`: Anchor side of the tag (`:top`, `:top_right`, `:right`, `:bottom_right`, `:bottom`, `:bottom_left`, `:left`, `:top_left`).
- `tag_pos::Float64 = 0.5`: Position along the curve in [0,1].
- `tag_orientation::Symbol = :horizontal`: Tag orientation (`:horizontal`, `:vertical`, `:parallel`).
- `tag_padding::Union{Nothing,Real} = nothing`: Padding between the curve and tag in points. `nothing` uses the default based on font size.
- `tag_font_size::Union{Nothing,Real} = nothing`: Tag font size in points. `nothing` uses `0.8 * chart.xaxis.font_size`.
- `order::Int = 0`: Z-order. If `0`, an incremental order is assigned.

# Returns
- The created series object.
"""
function add_line(chart::Chart, X::AbstractVector, Y::AbstractVector; kwargs...)
    return add_series(chart, LineSeries(X, Y; kwargs...))
end

"""
    add_scatter(chart::Chart, X::AbstractVector, Y::AbstractVector; kwargs...)

Add a scatter series to `chart`.

This is a convenience wrapper around [`LineSeries`](@ref) plus
[`add_series`](@ref), with `line_style=:none` and `mark=:circle` unless those
keywords are supplied.

# Arguments
- `chart::Chart`: Target chart (mutated).
- `X, Y::AbstractVector`: Data vectors.
- `kwargs...`: Keyword arguments accepted by [`add_line`](@ref); explicit values override the defaults above.

# Returns
- The created series object.
"""
function add_scatter(chart::Chart, X::AbstractVector, Y::AbstractVector; kwargs...)
    defaults = (line_style=:none, mark=:circle)
    return add_series(chart, LineSeries(X, Y; merge(defaults, kwargs)...))
end

"""
    add_bar(chart::Chart, X::AbstractVector, Y::AbstractVector; kwargs...)

Add a bar series to `chart`.

Construct a [`BarSeries`](@ref), attach it to `chart`, and return it.

# Arguments
- `chart::Chart`: Target chart (mutated).
- `X, Y::AbstractVector`: Data vectors.
- `color::Union{Symbol,Color,Tuple} = :auto`: Bar fill color. `:auto` selects from the chart palette cyclically.
- `line_width::Float64 = 0.5`: Outline width (> 0).
- `label::AbstractString = ""`: Legend label.
- `bar_width::Float64 = 0.0`: Bar width in x-data units (`0` enables auto width).
- `bar_base::Float64 = 0.0`: Bar baseline in y-data units.
- `order::Int = 0`: Z-order. If `0`, an incremental order is assigned.

# Returns
- The created series object.
"""
function add_bar(
    chart::Chart,
    X::AbstractVector,
    Y::AbstractVector;
    color::Union{Symbol,Color,Tuple}=:auto,
    line_width=0.5,
    label="",
    bar_width=0.0,
    bar_base=0.0,
    order=0,
)
    return add_series(chart, BarSeries(X, Y; color=color, line_width=line_width, label=label, bar_width=bar_width, bar_base=bar_base, order=order))
end

"""
    add_contour(chart::Chart, x::AbstractVector, y::AbstractVector, z::AbstractMatrix; kwargs...)

Add a contour series to `chart`.

Set `filled=true` to draw filled contour bands. Filled contours draw contour
lines too unless `line_style=:none`.
"""
function add_contour(
    chart::Chart,
    x::AbstractVector,
    y::AbstractVector,
    z::AbstractMatrix;
    filled::Bool=false,
    levels=nothing,
    nlevels::Int=10,
    label::AbstractString="",
    order::Int=0,
    color=:auto,
    line_width::Real=0.5,
    line_style::Symbol=:solid,
    colormap=Colormap(:viridis),
    alpha::Real=1.0,
    colorbar::Symbol=:right,
    colorbar_ratio::Real=1.0,
    colorbar_label::AbstractString="",
    colorbar_ticks::AbstractVector{<:Real}=Float64[],
    colorbar_tick_labels::AbstractVector{<:AbstractString}=String[],
)
    series = ContourSeries(
        x,
        y,
        z;
        filled=filled,
        levels=levels,
        nlevels=nlevels,
        label=label,
        order=order,
        color=color,
        line_width=line_width,
        line_style=line_style,
        colormap=colormap,
        alpha=alpha,
        colorbar=colorbar,
        colorbar_ratio=colorbar_ratio,
        colorbar_label=colorbar_label,
        colorbar_ticks=colorbar_ticks,
        colorbar_tick_labels=colorbar_tick_labels,
    )
    return add_series(chart, series)
end


function _quiver_vector_stride(stride)
    stride isa Integer || throw(ArgumentError("add_quiver: stride must be a positive integer for vector inputs"))
    stride > 0 || throw(ArgumentError("add_quiver: stride must be positive"))
    return Int(stride)
end


function _quiver_grid_stride(stride)
    if stride isa Integer
        stride > 0 || throw(ArgumentError("add_quiver: stride must be positive"))
        s = Int(stride)
        return s, s
    elseif stride isa Tuple && length(stride) == 2 && all(value -> value isa Integer, stride)
        sx = Int(stride[1])
        sy = Int(stride[2])
        sx > 0 && sy > 0 || throw(ArgumentError("add_quiver: stride components must be positive"))
        return sx, sy
    end
    throw(ArgumentError("add_quiver: stride must be a positive integer or a pair of positive integers for grid inputs"))
end


function _quiver_grid_vectors(x::AbstractVector, y::AbstractVector, U::AbstractMatrix, V::AbstractMatrix, stride)
    length(x) > 0 || throw(ArgumentError("add_quiver: x must contain at least one point"))
    length(y) > 0 || throw(ArgumentError("add_quiver: y must contain at least one point"))
    size(U) == (length(y), length(x)) || throw(ArgumentError("add_quiver: size(U) must equal (length(y), length(x))"))
    size(V) == (length(y), length(x)) || throw(ArgumentError("add_quiver: size(V) must equal (length(y), length(x))"))

    sx, sy = _quiver_grid_stride(stride)
    X = Float64[]
    Y = Float64[]
    Uflat = Float64[]
    Vflat = Float64[]

    for iy in 1:sy:length(y)
        for ix in 1:sx:length(x)
            push!(X, float(x[ix]))
            push!(Y, float(y[iy]))
            push!(Uflat, float(U[iy, ix]))
            push!(Vflat, float(V[iy, ix]))
        end
    end

    return X, Y, Uflat, Vflat
end


"""
    add_quiver(chart::Chart, X::AbstractVector, Y::AbstractVector, U::AbstractVector, V::AbstractVector; kwargs...)

Add a quiver/vector-field series to `chart` from flat anchor and vector arrays.

Arrows are normalized in screen space so the longest visible arrow is drawn
with length `max_length` points.
"""
function add_quiver(
    chart::Chart,
    X::AbstractVector,
    Y::AbstractVector,
    U::AbstractVector,
    V::AbstractVector;
    color::Union{Symbol,Color,Tuple}=:black,
    line_width::Real=0.5,
    max_length::Real=12.0,
    head_length::Real=4.0,
    stride=1,
    label::AbstractString="",
    order::Int=0,
)
    s = _quiver_vector_stride(stride)
    series = QuiverSeries(
        X[1:s:end],
        Y[1:s:end],
        U[1:s:end],
        V[1:s:end];
        color=color,
        line_width=line_width,
        max_length=max_length,
        head_length=head_length,
        label=label,
        order=order,
    )
    return add_series(chart, series)
end


"""
    add_quiver(chart::Chart, x::AbstractVector, y::AbstractVector, U::AbstractMatrix, V::AbstractMatrix; kwargs...)

Add a quiver/vector-field series to `chart` from a rectilinear grid.

`U` and `V` must have size `(length(y), length(x))`.
"""
function add_quiver(
    chart::Chart,
    x::AbstractVector,
    y::AbstractVector,
    U::AbstractMatrix,
    V::AbstractMatrix;
    color::Union{Symbol,Color,Tuple}=:black,
    line_width::Real=0.5,
    max_length::Real=12.0,
    head_length::Real=4.0,
    stride=1,
    label::AbstractString="",
    order::Int=0,
)
    X, Y, Uflat, Vflat = _quiver_grid_vectors(x, y, U, V, stride)
    series = QuiverSeries(
        X,
        Y,
        Uflat,
        Vflat;
        color=color,
        line_width=line_width,
        max_length=max_length,
        head_length=head_length,
        label=label,
        order=order,
    )
    return add_series(chart, series)
end


function _tag_anchor_alignment(anchor::Symbol)
    anchor == :top && return "center", "top"
    anchor == :top_right && return "right", "top"
    anchor == :right && return "right", "center"
    anchor == :bottom_right && return "right", "bottom"
    anchor == :bottom && return "center", "bottom"
    anchor == :bottom_left && return "left", "bottom"
    anchor == :left && return "left", "center"
    anchor == :top_left && return "left", "top"
    throw(ArgumentError("Invalid tag anchor: $anchor"))
end


function _tag_anchor_offset(anchor::Symbol, pad::Float64)
    anchor == :top && return 0.0, pad
    anchor == :top_right && return -pad, pad
    anchor == :right && return -pad, 0.0
    anchor == :bottom_right && return -pad, -pad
    anchor == :bottom && return 0.0, -pad
    anchor == :bottom_left && return pad, -pad
    anchor == :left && return pad, 0.0
    anchor == :top_left && return pad, pad
    throw(ArgumentError("Invalid tag anchor: $anchor"))
end


function _rotate_offset(dx::Float64, dy::Float64, angle::Float64)
    c = cosd(angle)
    s = sind(angle)
    return dx * c + dy * s, -dx * s + dy * c
end

const _debug_tag_points = Ref(false)


function _resolve_tag_layout(anchor::Symbol, orientation::Symbol, tangent_angle::Float64, pad::Float64)
    ha, va = _tag_anchor_alignment(anchor)
    dx, dy = _tag_anchor_offset(anchor, pad)

    angle = if orientation == :parallel
        tangent_angle
    elseif orientation == :vertical
        90.0
    else
        0.0
    end

    if angle != 0.0
        dx, dy = _rotate_offset(dx, dy, angle)
    end

    return ha, va, dx, dy, angle
end


_tag_vertex_tolerance(total_length::Float64) = max(1.0e-12, sqrt(eps(Float64)) * max(total_length, 1.0))


function _segment_tangent_angle(canvas::Canvas, X::AbstractArray, Y::AbstractArray, i::Int)
    x1, y1 = data2user(canvas, float(X[i]), float(Y[i]))
    x2, y2 = data2user(canvas, float(X[i + 1]), float(Y[i + 1]))
    return -atand(y2 - y1, x2 - x1)
end


function _vertex_tangent_angle(canvas::Canvas, X::AbstractArray, Y::AbstractArray, i::Int)
    xprev, yprev = data2user(canvas, float(X[i - 1]), float(Y[i - 1]))
    xnext, ynext = data2user(canvas, float(X[i + 1]), float(Y[i + 1]))
    dx = xnext - xprev
    dy = ynext - yprev

    if isapprox(dx, 0.0; atol=1.0e-12) && isapprox(dy, 0.0; atol=1.0e-12)
        return _segment_tangent_angle(canvas, X, Y, i)
    end

    return -atand(dy, dx)
end


function _resolve_tag_point_and_tangent(canvas::Canvas, X::AbstractArray, Y::AbstractArray, tag_pos::Float64)
    len = 0.0
    lengths = Float64[0.0]
    for i in 2:length(X)
        len += norm((float(X[i]) - float(X[i - 1]), float(Y[i]) - float(Y[i - 1])))
        push!(lengths, len)
    end

    lpos = tag_pos * len
    tol = _tag_vertex_tolerance(len)
    vertex = findfirst(value -> abs(value - lpos) <= tol, lengths)

    if vertex !== nothing
        x, y = data2user(canvas, float(X[vertex]), float(Y[vertex]))
        tangent_angle = if vertex == 1
            _segment_tangent_angle(canvas, X, Y, 1)
        elseif vertex == length(lengths)
            _segment_tangent_angle(canvas, X, Y, length(lengths) - 1)
        else
            _vertex_tangent_angle(canvas, X, Y, vertex)
        end
        return x, y, tangent_angle
    end

    i = clamp(searchsortedlast(lengths, lpos), 1, length(lengths) - 1)
    t = (lpos - lengths[i]) / (lengths[i + 1] - lengths[i])
    x = float(X[i]) + t * (float(X[i + 1]) - float(X[i]))
    y = float(Y[i]) + t * (float(Y[i + 1]) - float(Y[i]))
    x, y = data2user(canvas, x, y)
    tangent_angle = _segment_tangent_angle(canvas, X, Y, i)
    return x, y, tangent_angle
end


"""
    configure!(figure)

Compute layout-dependent fields for `figure` in place.

`save` calls this automatically before rendering, so users usually do not need
to call it directly. Calling it manually is useful when inspecting computed axis
limits, tick labels, plot frames, legend frames, or grid cell frames before
rendering. `Chart` values must contain at least one data series, and
`ChartGrid` values must contain at least one child figure.

Returns the configured object for methods that expose a return value; callers
should rely on the mutation, not on a particular return.
"""
function configure!(c::Chart)

    length(c.dataseries) > 0 || throw(QuickChartsException("No dataseries added to the chart"))

    c.outerpad = 0.01 * min(c.width, c.height)
    c.figure_frame = Frame(c.figure_frame.x, c.figure_frame.y, c.width, c.height)

    configure!(c, c.xaxis, c.yaxis)
    _prepare_chart_side_items!(c)

    _assign_chart_frames!(c)

end


function configure!(c::Chart, canvas::Canvas)
    canvas.limits = [c.xaxis.limits[1], c.yaxis.limits[1], c.xaxis.limits[2], c.yaxis.limits[2]]
end


function configure!(chart::Chart, xax::Axis, yax::Axis)

    for ax in (xax, yax)
        if ax.auto_limits
            extent = ax.manual_ticks && !isempty(ax.ticks) ? collect(extrema(ax.ticks)) : _chart_axis_data_extent(chart, ax)
            ax.limits = compute_auto_limits(extent)
        end
    end

    configure!(xax)
    configure!(yax)

end


function _chart_bar_width(series::BarSeries)
    w = series.bar_width
    if w == 0
        Xu = unique(sort(collect(series.X)))
        if length(Xu) > 1
            w = 0.56 * abs(minimum(diff(Xu)))
        else
            xspan = abs(maximum(series.X) - minimum(series.X))
            w = xspan > 0 ? 0.035 * xspan : 1.0
        end
    end
    return w
end


function _chart_legend_plots(c::Chart)
    return [p for p in c.dataseries if _series_has_legend_entry(p)]
end


_contour_uses_line_colormap(series::ContourSeries) = series.color === :auto
_contour_has_colorbar(series::ContourSeries) = series.colorbar_location != :none && (series.filled || _contour_uses_line_colormap(series))
_series_has_legend_entry(series::DataSeries) = series.label != ""
_series_has_legend_entry(series::ContourSeries) = series.label != "" && !_contour_has_colorbar(series)


function _series_axis_extent(series::LineSeries, ax::Axis)
    if ax.direction == :horizontal
        isempty(series.X) && return nothing
        return minimum(series.X), maximum(series.X)
    end

    isempty(series.Y) && return nothing
    return minimum(series.Y), maximum(series.Y)
end


function _series_axis_extent(series::BarSeries, ax::Axis)
    if ax.direction == :horizontal
        isempty(series.X) && return nothing
        w = _chart_bar_width(series)
        return minimum(series.X) - 0.5 * w, maximum(series.X) + 0.5 * w
    end

    isempty(series.Y) && return nothing
    base = series.bar_base
    return minimum(min.(series.Y, base)), maximum(max.(series.Y, base))
end


function _series_axis_extent(series::QuiverSeries, ax::Axis)
    if ax.direction == :horizontal
        isempty(series.X) && return nothing
        return minimum(series.X), maximum(series.X)
    end

    isempty(series.Y) && return nothing
    return minimum(series.Y), maximum(series.Y)
end


function _series_axis_extent(series::ContourSeries, ax::Axis)
    if ax.direction == :horizontal
        isempty(series.x) && return nothing
        return minimum(series.x), maximum(series.x)
    end

    isempty(series.y) && return nothing
    return minimum(series.y), maximum(series.y)
end


function _chart_contour_colorbars(c::Chart)
    colorbars = Colorbar[]
    for series in c.dataseries
        series isa ContourSeries || continue
        _contour_has_colorbar(series) || continue
        bins = max(2, min(length(series.levels), 6))
        colorbar_label = isempty(series.colorbar_label) ? series.label : series.colorbar_label
        colorbar_ticks = isempty(series.colorbar_ticks) ? series.levels : series.colorbar_ticks
        push!(
            colorbars,
            Colorbar(
                location=series.colorbar_location,
                colormap=series.colormap,
                limits=[series.colormap.stops[1], series.colormap.stops[end]],
                label=colorbar_label,
                font_size=c.xaxis.font_size,
                font=c.xaxis.font,
                ticks=colorbar_ticks,
                tick_labels=series.colorbar_tick_labels,
                bins=bins,
                length_factor=series.colorbar_ratio,
                discrete=series.filled,
                levels=series.levels,
            ),
        )
    end
    return colorbars
end


function _chart_side_pane_size(items::Vector{FigureComponent}, side::Symbol)
    isempty(items) && return 0.0
    if side in (:left, :right)
        return maximum(item.width for item in items)
    end
    return maximum(item.height for item in items)
end


function _chart_vertical_side_overhang(items::Vector{FigureComponent})
    top = 0.0
    bottom = 0.0

    for item in items
        item isa Colorbar || continue
        item.location in (:left, :right) || continue
        _, tick_label_height = _axis_tick_label_extent(item.axis)
        top = max(top, 0.5 * tick_label_height + axis_top_overhang(item.axis))
        bottom = max(bottom, 0.5 * tick_label_height)
    end

    return top, bottom
end


function _chart_assign_side_frames!(c::Chart, items::Vector{FigureComponent}, side::Symbol, pane_size::Float64)
    isempty(items) && return nothing

    plot = c.canvas.frame
    if side in (:left, :right)
        gap = length(items) > 1 ? 0.05 * plot.height : 0.0
        slot_length = (plot.height - (length(items) - 1) * gap) / length(items)
        pane_x = side == :left ? plot.x - pane_size : plot.x + plot.width
        for (i, item) in enumerate(items)
            cb = item::Colorbar
            slot_y = plot.y + (i - 1) * (slot_length + gap)
            cb.height = cb.length_factor * slot_length
            cb.axis.height = cb.height
            cb.frame = Frame(pane_x, slot_y, pane_size, slot_length)
        end
    else
        gap = length(items) > 1 ? 0.05 * plot.width : 0.0
        slot_length = (plot.width - (length(items) - 1) * gap) / length(items)
        pane_y = side == :top ? plot.y - pane_size : plot.y + plot.height
        for (i, item) in enumerate(items)
            cb = item::Colorbar
            slot_x = plot.x + (i - 1) * (slot_length + gap)
            cb.width = cb.length_factor * slot_length
            cb.axis.width = cb.width
            cb.frame = Frame(slot_x, pane_y, slot_length, pane_size)
        end
    end

    return nothing
end


function _legend_measure_context(legend::Legend)
    surf = CairoImageSurface(4, 4, Cairo.FORMAT_ARGB32)
    cc = CairoContext(surf)
    font = get_font(legend.font)
    select_font_face(cc, font, Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL)
    set_font_size(cc, legend.font_size)
    return cc
end


function _legend_layout(legend::Legend, plots, cairo_ctx::CairoContext)
    nlabels = length(plots)
    ncols = legend.ncols
    nrows = ceil(Int, nlabels / ncols)
    nlabels == 0 && return zeros(ncols), Float64[], 0.0, 0.0

    col_widths = zeros(ncols)
    row_heights = zeros(nrows)
    vertical_pad = legend.row_sep

    for (k, plot) in enumerate(plots)
        i = ceil(Int, k / ncols)  # row
        j = k % ncols == 0 ? ncols : k % ncols # column
        label_width, current_height = getsize(cairo_ctx, plot.label, legend.font_size)
        item_width = legend.handle_length + 2 * legend.inner_pad + label_width
        col_widths[j] = max(col_widths[j], item_width)
        row_heights[i] = max(row_heights[i], current_height)
    end

    width = sum(col_widths) + (ncols - 1) * legend.col_sep + 2 * legend.inner_pad
    height = sum(row_heights) + (nrows - 1) * legend.row_sep + 2 * vertical_pad

    return col_widths, row_heights, width, height
end


function _chart_axis_data_extent(chart::Chart, ax::Axis)
    lower = Inf
    upper = -Inf

    for series in chart.dataseries
        extent = _series_axis_extent(series, ax)
        extent === nothing && continue
        lower = min(lower, extent[1])
        upper = max(upper, extent[2])
    end

    return isfinite(lower) && isfinite(upper) ? [lower, upper] : [0.0, 1.0]
end


function configure!(c::Chart, legend::Legend)
    legend.handle_length = 1.9 * legend.font_size
    legend.row_sep = 0.3 * legend.font_size
    legend.col_sep = 1.5 * legend.font_size
    legend.inner_pad = 1.5 * legend.row_sep
    legend.outer_pad = legend.inner_pad

    plots = _chart_legend_plots(c)
    cc = _legend_measure_context(legend)
    _, _, legend.width, legend.height = _legend_layout(legend, plots, cc)
end


function _chart_title_font_size(c::Chart)
    return 1.2 * c.xaxis.font_size
end


function _chart_title_height(c::Chart)
    isempty(c.title_box.text) && return 0.0
    surf = CairoImageSurface(4, 4, Cairo.FORMAT_ARGB32)
    cc = CairoContext(surf)
    select_font_face(cc, get_font(c.xaxis.font), Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL)
    set_font_size(cc, _chart_title_font_size(c))
    return getsize(cc, c.title_box.text, _chart_title_font_size(c))[2]
end


function _chart_has_legend(c::Chart)
    return !isempty(_chart_legend_plots(c))
end


function _prepare_chart_side_items!(c::Chart)
    _chart_has_legend(c) && configure!(c, c.legend)
    c.left_items = FigureComponent[]
    c.right_items = FigureComponent[]
    c.top_items = FigureComponent[]
    c.bottom_items = FigureComponent[]

    for cb in _chart_contour_colorbars(c)
        configure!(c, cb)
        if cb.location == :left
            push!(c.left_items, cb)
        elseif cb.location == :right
            push!(c.right_items, cb)
        elseif cb.location == :top
            push!(c.top_items, cb)
        elseif cb.location == :bottom
            push!(c.bottom_items, cb)
        end
    end

    return nothing
end


function _chart_plot_frame(c::Chart)
    left_margin = c.outerpad + c.yaxis.width
    right_margin = c.outerpad
    top_margin = c.outerpad + axis_top_overhang(c.yaxis)
    bottom_margin = c.outerpad + c.xaxis.height
    title_height = _chart_title_height(c)
    title_gap = isempty(c.title_box.text) ? 0.0 : 0.6 * c.xaxis.font_size

    top_margin += title_height + title_gap

    left_pane = _chart_side_pane_size(c.left_items, :left)
    right_pane = _chart_side_pane_size(c.right_items, :right)
    top_pane = _chart_side_pane_size(c.top_items, :top)
    bottom_pane = _chart_side_pane_size(c.bottom_items, :bottom)
    left_top_overhang, left_bottom_overhang = _chart_vertical_side_overhang(c.left_items)
    right_top_overhang, right_bottom_overhang = _chart_vertical_side_overhang(c.right_items)

    left_margin += left_pane
    right_margin += right_pane
    top_margin += top_pane
    bottom_margin += bottom_pane
    top_margin += max(left_top_overhang, right_top_overhang)
    bottom_margin += max(left_bottom_overhang, right_bottom_overhang)

    if _chart_has_legend(c)
        legend = c.legend
        if legend.location in (:outer_top_right, :outer_right, :outer_bottom_right)
            right_margin += c.outerpad + legend.width
        elseif legend.location in (:outer_top_left, :outer_left, :outer_bottom_left)
            left_margin += c.outerpad + legend.width
        elseif legend.location == :outer_top
            top_margin += legend.height + c.outerpad
        elseif legend.location == :outer_bottom
            bottom_margin += legend.height + c.outerpad
        end
    end

    width = c.width - left_margin - right_margin
    height = c.height - top_margin - bottom_margin
    frame = Frame(c.figure_frame.x + left_margin, c.figure_frame.y + top_margin, width, height)

    # Ensure the last horizontal tick label fits inside the figure frame.
    if isempty(c.xaxis.ticks) || isempty(c.xaxis.tick_labels)
        extra_right = 0.0
    else
        right_gap = minimum((frame.x + frame.width) - (frame.x + frame.width / (c.xaxis.limits[2] - c.xaxis.limits[1]) * (tick - c.xaxis.limits[1])) for tick in c.xaxis.ticks)
        extra_right = max(0.0, getsize(c.xaxis.tick_labels[end], c.xaxis.font_size)[1] / 2 - right_gap)
    end

    # Ensure the top-most vertical tick label fits inside the figure frame.
    if isempty(c.yaxis.ticks) || isempty(c.yaxis.tick_labels)
        extra_top = 0.0
    else
        top_gap = minimum(frame.y + frame.height / (c.yaxis.limits[2] - c.yaxis.limits[1]) * (c.yaxis.limits[2] - tick) - frame.y for tick in c.yaxis.ticks)
        extra_top = max(0.0, getsize(c.yaxis.tick_labels[end], c.yaxis.font_size)[2] / 2 - top_gap)
    end

    return Frame(c.figure_frame.x + left_margin, c.figure_frame.y + top_margin + extra_top, width - extra_right, height - extra_top)
end


function _chart_canvas_frame(c::Chart, plot_frame::Frame)
    c.aspect_ratio == :auto && return plot_frame

    xmin, xmax = c.xaxis.limits
    ymin, ymax = c.yaxis.limits
    dx = abs(xmax - xmin)
    dy = abs(ymax - ymin)
    (dx > 0 && dy > 0) || return plot_frame

    ratio = min(plot_frame.width / dx, plot_frame.height / dy)
    width = ratio * dx
    height = ratio * dy
    x = plot_frame.x + 0.5 * (plot_frame.width - width)
    y = plot_frame.y + 0.5 * (plot_frame.height - height)

    return Frame(x, y, width, height)
end


function _assign_chart_frames!(c::Chart)
    plot_frame = _chart_plot_frame(c)
    plot_frame.width > 0 && plot_frame.height > 0 || throw(ArgumentError("Chart: insufficient space for plot area"))
    canvas_frame = _chart_canvas_frame(c, plot_frame)

    c.canvas.frame = canvas_frame
    configure!(c, c.canvas)

    c.xaxis.width = canvas_frame.width
    c.xaxis.frame = Frame(canvas_frame.x, canvas_frame.y + canvas_frame.height, canvas_frame.width, c.xaxis.height)

    c.yaxis.height = canvas_frame.height
    c.yaxis.frame = Frame(canvas_frame.x - c.yaxis.width, canvas_frame.y, c.yaxis.width, canvas_frame.height)

    c.overlay_items = FigureComponent[a for a in c.annotations]

    if !isempty(c.title_box.text)
        title_height = _chart_title_height(c)
        y = c.figure_frame.y + c.outerpad
        c.title_box.frame = Frame(plot_frame.x, y, plot_frame.width, title_height)
        c.title_box.angle = 0.0
    else
        c.title_box.frame = Frame()
    end

    if _chart_has_legend(c)
        _assign_legend_frame!(c, c.legend)
    else
        c.legend.frame = Frame()
    end

    _chart_assign_side_frames!(c, c.left_items, :left, _chart_side_pane_size(c.left_items, :left))
    _chart_assign_side_frames!(c, c.right_items, :right, _chart_side_pane_size(c.right_items, :right))
    _chart_assign_side_frames!(c, c.top_items, :top, _chart_side_pane_size(c.top_items, :top))
    _chart_assign_side_frames!(c, c.bottom_items, :bottom, _chart_side_pane_size(c.bottom_items, :bottom))
end


function _assign_legend_frame!(c::Chart, legend::Legend)
    plot = c.canvas.frame
    outer_pad = legend.outer_pad

    if legend.location in (:top_right, :right, :bottom_right)
        x1 = plot.x + plot.width - outer_pad - legend.width
    elseif legend.location in (:top, :bottom, :outer_top, :outer_bottom)
        x1 = plot.x + 0.5 * (plot.width - legend.width)
    elseif legend.location in (:top_left, :left, :bottom_left)
        x1 = plot.x + outer_pad
    elseif legend.location in (:outer_top_left, :outer_left, :outer_bottom_left)
        x1 = c.figure_frame.x + c.outerpad
    elseif legend.location in (:outer_top_right, :outer_right, :outer_bottom_right)
        x1 = c.figure_frame.x + c.width - legend.width - c.outerpad
    else
        error("Chart: unsupported legend location $(legend.location)")
    end

    if legend.location in (:top_left, :top, :top_right)
        y1 = plot.y + outer_pad
    elseif legend.location in (:left, :right, :outer_left, :outer_right)
        y1 = plot.y + 0.5 * (plot.height - legend.height)
    elseif legend.location in (:bottom_left, :bottom, :bottom_right)
        y1 = plot.y + plot.height - outer_pad - legend.height
    elseif legend.location == :outer_top
        y1 = c.figure_frame.y + c.outerpad + _chart_title_height(c) + (isempty(c.title_box.text) ? 0.0 : 0.6 * c.xaxis.font_size)
    elseif legend.location == :outer_bottom
        y1 = c.figure_frame.y + c.height - legend.height - c.outerpad
    elseif legend.location in (:outer_top_left, :outer_top_right)
        y1 = plot.y
    elseif legend.location in (:outer_bottom_left, :outer_bottom_right)
        y1 = plot.y + plot.height - legend.height
    else
        error("Chart: unsupported legend location $(legend.location)")
    end

    legend.frame = Frame(x1, y1, legend.width, legend.height)

    return nothing
end


function _contour_line_color(p::ContourSeries, level::Float64)
    return p.color === :auto ? Color(p.colormap(level)) : p.color
end


function _set_contour_line_dash!(cairo_ctx::CairoContext, line_style::Symbol, line_width::Float64)
    line_style == :solid && return nothing
    line_style == :dash && return set_dash(cairo_ctx, [4.0, 2.4] .* line_width)
    line_style == :dashdot && return set_dash(cairo_ctx, [2.0, 1.0, 2.0, 1.0] .* line_width)
    line_style == :dot && return set_dash(cairo_ctx, [1.0, 1.0] .* line_width)
    return nothing
end


_contour_fill_seam_width(::RenderContext) = 0.25


_effective_arrow_head_length(length::Float64, requested::Float64) = min(requested, 0.6 * length)


function _draw_filled_arrow!(cairo_ctx::CairoContext, x1::Float64, y1::Float64, x2::Float64, y2::Float64; head_length::Float64)
    Δx = x2 - x1
    Δy = y2 - y1
    length = hypot(Δx, Δy)
    length < 1.0e-8 && return nothing

    head = _effective_arrow_head_length(length, head_length)
    if length < 0.8 * head
        move_to(cairo_ctx, x1, y1)
        line_to(cairo_ctx, x2, y2)
        stroke(cairo_ctx)
        return nothing
    end

    ux = Δx / length
    uy = Δy / length
    nx = -uy
    ny = ux

    base_x = x2 - head * ux
    base_y = y2 - head * uy
    half_width = 0.45 * head

    move_to(cairo_ctx, x1, y1)
    line_to(cairo_ctx, base_x, base_y)
    stroke(cairo_ctx)

    move_to(cairo_ctx, x2, y2)
    line_to(cairo_ctx, base_x + half_width * nx, base_y + half_width * ny)
    line_to(cairo_ctx, base_x - half_width * nx, base_y - half_width * ny)
    close_path(cairo_ctx)
    fill(cairo_ctx)

    return nothing
end


function draw!(c::Chart, ctx::RenderContext, canvas::Canvas)
    # draw grid
    cairo_ctx = ctx.cairo_ctx
    reset_matrix!(ctx)
    set_source_rgba(cairo_ctx, rgba(_chart_gridline_color(c, ctx))...)
    set_line_width(cairo_ctx, 0.2 * ctx.width_scale)
    x0 = canvas.frame.x
    y0 = canvas.frame.y
    x1 = canvas.frame.x + canvas.frame.width
    y1 = canvas.frame.y + canvas.frame.height

    xmin, xmax = c.xaxis.limits
    for x in c.xaxis.ticks
        min(xmax, xmin) <= x <= max(xmax, xmin) || continue
        xc = x0 + canvas.frame.width / (xmax - xmin) * (x - xmin)
        move_to(cairo_ctx, xc, y0)
        line_to(cairo_ctx, xc, y1)
        stroke(cairo_ctx)
    end

    ymin, ymax = c.yaxis.limits
    for y in c.yaxis.ticks
        min(ymax, ymin) <= y <= max(ymax, ymin) || continue
        yc = y0 + canvas.frame.height / (ymax - ymin) * (ymax - y)
        move_to(cairo_ctx, x0, yc)
        line_to(cairo_ctx, x1, yc)
        stroke(cairo_ctx)
    end

    # draw border
    set_source_rgb(cairo_ctx, 0.0, 0.0, 0.0)
    set_line_width(cairo_ctx, 0.5 * ctx.width_scale)
    rectangle(cairo_ctx, x0, y0, canvas.frame.width, canvas.frame.height)
    stroke(cairo_ctx)
end


function draw!(chart::Chart, ctx::RenderContext, p::BarSeries)
    cairo_ctx = ctx.cairo_ctx

    reset_matrix!(ctx)
    set_source_rgb(cairo_ctx, rgb(p.color)...)
    set_line_width(cairo_ctx, p.line_width * ctx.width_scale)
    set_line_join(cairo_ctx, Cairo.CAIRO_LINE_JOIN_ROUND)

    n = length(p.X)
    X = float.(p.X)
    Y = float.(p.Y)
    xmin, xmax = chart.xaxis.limits
    xspan = abs(xmax - xmin)

    w = p.bar_width
    if w == 0
        if n > 1
            Xu = unique(sort(collect(X)))
            if length(Xu) > 1
                dx = minimum(diff(Xu))
                w = 0.56 * abs(dx)
            end
        end
        w == 0 && (w = xspan > 0 ? 0.035 * xspan : 1.0)
    end
    base = p.bar_base

    for (x, y) in zip(X, Y)
        y0 = base
        h = y - y0
        xleft = x - 0.5 * w
        ytop = h >= 0 ? y : y0
        rect_x, rect_y = data2user(chart.canvas, xleft, ytop)
        xden = abs(chart.xaxis.limits[2] - chart.xaxis.limits[1])
        yden = abs(chart.yaxis.limits[2] - chart.yaxis.limits[1])
        rect_w = xden > 0 ? chart.canvas.frame.width / xden * w : 0.0
        rect_h = yden > 0 ? chart.canvas.frame.height / yden * abs(h) : 0.0

        rectangle(cairo_ctx, rect_x, rect_y, rect_w, rect_h)
        fill_preserve(cairo_ctx)
        set_source_rgb(cairo_ctx, 0.0, 0.0, 0.0)
        set_line_width(cairo_ctx, p.line_width * ctx.width_scale)
        stroke(cairo_ctx)
        set_source_rgb(cairo_ctx, rgb(p.color)...)
    end
end


function draw!(chart::Chart, ctx::RenderContext, p::QuiverSeries)
    cairo_ctx = ctx.cairo_ctx
    reset_matrix!(ctx)
    set_source_rgb(cairo_ctx, rgb(p.color)...)
    set_line_width(cairo_ctx, p.line_width * ctx.width_scale)
    set_line_join(cairo_ctx, Cairo.CAIRO_LINE_JOIN_ROUND)
    set_line_cap(cairo_ctx, Cairo.CAIRO_LINE_CAP_ROUND)

    X = float.(p.X)
    Y = float.(p.Y)
    U = float.(p.U)
    V = float.(p.V)

    valid = Tuple{Float64,Float64,Float64,Float64,Float64,Float64}[]
    maxnorm = 0.0

    for (x, y, u, v) in zip(X, Y, U, V)
        isfinite(x) && isfinite(y) && isfinite(u) && isfinite(v) || continue
        x1, y1 = data2user(chart.canvas, x, y)
        x2, y2 = data2user(chart.canvas, x + u, y + v)
        Δx = x2 - x1
        Δy = y2 - y1
        length = hypot(Δx, Δy)
        length > 1.0e-12 || continue
        push!(valid, (x1, y1, Δx, Δy, x2, y2))
        maxnorm = max(maxnorm, length)
    end

    maxnorm > 0 || return nothing

    scale = p.max_length / maxnorm
    for (x1, y1, Δx, Δy, _, _) in valid
        _draw_filled_arrow!(cairo_ctx, x1, y1, x1 + scale * Δx, y1 + scale * Δy; head_length=p.head_length)
    end

    return nothing
end


function draw!(chart::Chart, ctx::RenderContext, p::ContourSeries)
    cairo_ctx = ctx.cairo_ctx
    reset_matrix!(ctx)

    if p.filled
        for band in p.fill_bands
            isempty(band.polygons) && continue
            midpoint = 0.5 * (band.lower + band.upper)
            r, g, b = p.colormap(midpoint)
            set_source_rgba(cairo_ctx, r, g, b, p.alpha)

            new_path(cairo_ctx)
            for polygon in band.polygons
                isempty(polygon) && continue
                x0, y0 = data2user(chart.canvas, polygon[1]...)
                move_to(cairo_ctx, x0, y0)
                for point in polygon[2:end]
                    x, y = data2user(chart.canvas, point...)
                    line_to(cairo_ctx, x, y)
                end
                close_path(cairo_ctx)
            end
            Cairo.set_fill_type(cairo_ctx, Cairo.CAIRO_FILL_RULE_EVEN_ODD)
            fill_preserve(cairo_ctx)
            set_line_join(cairo_ctx, Cairo.CAIRO_LINE_JOIN_ROUND)
            set_line_cap(cairo_ctx, Cairo.CAIRO_LINE_CAP_ROUND)
            set_line_width(cairo_ctx, _contour_fill_seam_width(ctx))
            stroke(cairo_ctx)
            Cairo.set_fill_type(cairo_ctx, Cairo.CAIRO_FILL_RULE_WINDING)
        end
    end

    if p.line_style != :none
        set_line_width(cairo_ctx, p.line_width * ctx.width_scale)
        set_line_join(cairo_ctx, Cairo.CAIRO_LINE_JOIN_ROUND)
        _set_contour_line_dash!(cairo_ctx, p.line_style, p.line_width)
        for (level, (x1d, y1d, x2d, y2d)) in p.line_segments
            set_source_rgb(cairo_ctx, rgb(_contour_line_color(p, level))...)
            x1, y1 = data2user(chart.canvas, x1d, y1d)
            x2, y2 = data2user(chart.canvas, x2d, y2d)
            move_to(cairo_ctx, x1, y1)
            line_to(cairo_ctx, x2, y2)
            stroke(cairo_ctx)
        end
        p.line_style != :solid && set_dash(cairo_ctx, Float64[])
    end
end


function draw!(chart::Chart, ctx::RenderContext, p::LineSeries)
    cairo_ctx = ctx.cairo_ctx

    p.mark_color = p.mark_color == :auto ? p.color : p.mark_color
    p.mark_stroke_color = p.mark_stroke_color == :auto ? p.color : p.mark_stroke_color

    reset_matrix!(ctx)
    set_source_rgb(cairo_ctx, rgb(p.color)...)
    set_line_width(cairo_ctx, p.line_width * ctx.width_scale)
    set_line_join(cairo_ctx, Cairo.CAIRO_LINE_JOIN_ROUND)

    new_path(cairo_ctx)
    n = length(p.X)
    X = float.(p.X)
    Y = float.(p.Y)

    if p.line_style !== :none
        x1, y1 = data2user(chart.canvas, X[1], Y[1])

        if p.line_style == :solid
            move_to(cairo_ctx, x1, y1)
            for i in 2:n
                x, y = data2user(chart.canvas, X[i], Y[i])
                line_to(cairo_ctx, x, y)
            end
            stroke(cairo_ctx)
        else # dashed
            len = sum(p.dash)
            offset = 0.0
            set_dash(cairo_ctx, p.dash, offset)
            move_to(cairo_ctx, x1, y1)
            for i in 2:n
                x, y = data2user(chart.canvas, X[i], Y[i])
                line_to(cairo_ctx, x, y)
                offset = mod(offset + norm((x1 - x, y1 - y)), len)
                set_dash(cairo_ctx, p.dash, offset)
                x1, y1 = x, y
            end
            stroke(cairo_ctx)
            set_dash(cairo_ctx, Float64[])
        end
    end

    # Draw marks
    for (x, y) in zip(X, Y)
        x, y = data2user(chart.canvas, x, y)
        draw_mark(cairo_ctx, x, y, p.mark, p.mark_size, p.mark_color, p.mark_stroke_color)
    end

    # Draw tag
    if p.tag != ""
        x, y, tangent_angle = _resolve_tag_point_and_tangent(chart.canvas, X, Y, p.tag_pos)

        pad = something(p.tag_padding, chart.xaxis.font_size * 0.3)
        tag_font_size = something(p.tag_font_size, chart.xaxis.font_size * 0.8)
        ha, va, dx, dy, α = _resolve_tag_layout(p.tag_anchor, p.tag_orientation, tangent_angle, pad)

        set_font_size(cairo_ctx, tag_font_size)
        font = get_font(chart.xaxis.font)
        select_font_face(cairo_ctx, font, Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL)
        set_source_rgb(cairo_ctx, 0, 0, 0)

        if _debug_tag_points[]
            # Debug overlay: red marks the sampled on-curve tag position, dark red
            # marks the final anchor point used to place the text box.
            set_source_rgb(cairo_ctx, 1.0, 0.0, 0.0)
            arc(cairo_ctx, x, y, 2.2, 0, 2pi)
            fill(cairo_ctx)
            set_source_rgb(cairo_ctx, 0.65, 0.0, 0.0)
            arc(cairo_ctx, x + dx, y + dy, 2.2, 0, 2pi)
            fill(cairo_ctx)
        end

        draw_text(cairo_ctx, x + dx, y + dy, p.tag, halign=ha, valign=va, angle=α)
    end

end


function draw!(c::Chart, ctx::RenderContext, legend::Legend)
    cairo_ctx = ctx.cairo_ctx

    plots = _chart_legend_plots(c)

    set_font_size(cairo_ctx, legend.font_size)
    font = get_font(legend.font)
    select_font_face(cairo_ctx, font, Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL)

    inner_pad = legend.inner_pad
    col_sep = legend.col_sep
    ncols = legend.ncols

    col_widths, row_heights, legend.width, legend.height = _legend_layout(legend, plots, cairo_ctx)

    x1 = legend.frame.x
    y1 = legend.frame.y
    x2 = legend.frame.x + legend.frame.width
    y2 = legend.frame.y + legend.frame.height

    reset_matrix!(ctx)

    # draw rounded rectangle
    r = 0.02 * min(c.canvas.frame.width, c.canvas.frame.height)
    move_to(cairo_ctx, x1, y1 + r)
    line_to(cairo_ctx, x1, y2 - r)
    curve_to(cairo_ctx, x1, y2, x1, y2, x1 + r, y2)
    line_to(cairo_ctx, x2 - r, y2)
    curve_to(cairo_ctx, x2, y2, x2, y2, x2, y2 - r)
    line_to(cairo_ctx, x2, y1 + r)
    curve_to(cairo_ctx, x2, y1, x2, y1, x2 - r, y1)
    line_to(cairo_ctx, x1 + r, y1)
    curve_to(cairo_ctx, x1, y1, x1, y1, x1, y1 + r)
    close_path(cairo_ctx)
    legend_background = something(legend.background, ctx.background, Color(:white))
    set_source_rgba(cairo_ctx, rgba(legend_background)...)
    fill_preserve(cairo_ctx)
    set_source_rgb(cairo_ctx, 0, 0, 0) # black
    set_line_width(cairo_ctx, 0.4 * ctx.width_scale)
    stroke(cairo_ctx)

    for (k, plot) in enumerate(plots)
        i = ceil(Int, k / ncols)  # line
        j = k % ncols == 0 ? ncols : k % ncols # column
        x2 = x1 + inner_pad + sum(col_widths[1:j-1]) + (j - 1) * col_sep

        y2 = y1 + legend.row_sep + sum(row_heights[1:i-1]) + (i - 1) * legend.row_sep + row_heights[i] / 2

        plot isa ContourSeries || set_source_rgb(cairo_ctx, rgb(plot.color)...)
        if plot isa BarSeries
            hbar = 0.6 * legend.font_size
            rectangle(cairo_ctx, x2, y2 - 0.5 * hbar, legend.handle_length, hbar)
            fill_preserve(cairo_ctx)
            set_source_rgb(cairo_ctx, 0.0, 0.0, 0.0)
            set_line_width(cairo_ctx, max(plot.line_width, 0.4) * ctx.width_scale)
            stroke(cairo_ctx)
            set_source_rgb(cairo_ctx, rgb(plot.color)...)
        elseif plot isa ContourSeries && plot.filled
            hbar = 0.6 * legend.font_size
            midpoint = 0.5 * (plot.levels[1] + plot.levels[end])
            r, g, b = plot.colormap(midpoint)
            set_source_rgba(cairo_ctx, r, g, b, plot.alpha)
            rectangle(cairo_ctx, x2, y2 - 0.5 * hbar, legend.handle_length, hbar)
            fill_preserve(cairo_ctx)
            if plot.line_style != :none
                set_source_rgb(cairo_ctx, rgb(_contour_line_color(plot, midpoint))...)
                set_line_width(cairo_ctx, max(plot.line_width, 0.4) * ctx.width_scale)
                _set_contour_line_dash!(cairo_ctx, plot.line_style, plot.line_width)
                move_to(cairo_ctx, x2, y2)
                rel_line_to(cairo_ctx, legend.handle_length, 0.0)
                stroke(cairo_ctx)
                set_dash(cairo_ctx, Float64[])
            end
        elseif plot isa ContourSeries
            midpoint = 0.5 * (plot.levels[1] + plot.levels[end])
            set_source_rgb(cairo_ctx, rgb(_contour_line_color(plot, midpoint))...)
            move_to(cairo_ctx, x2, y2)
            rel_line_to(cairo_ctx, legend.handle_length, 0)
            set_line_width(cairo_ctx, plot.line_width * ctx.width_scale)
            _set_contour_line_dash!(cairo_ctx, plot.line_style, plot.line_width)
            stroke(cairo_ctx)
            set_dash(cairo_ctx, Float64[])
        elseif plot isa QuiverSeries
            set_source_rgb(cairo_ctx, rgb(plot.color)...)
            set_line_width(cairo_ctx, plot.line_width * ctx.width_scale)
            set_line_join(cairo_ctx, Cairo.CAIRO_LINE_JOIN_ROUND)
            set_line_cap(cairo_ctx, Cairo.CAIRO_LINE_CAP_ROUND)
            _draw_filled_arrow!(cairo_ctx, x2, y2, x2 + legend.handle_length, y2; head_length=min(0.45 * legend.handle_length, plot.head_length))
        elseif plot.line_style != :none
            move_to(cairo_ctx, x2, y2)
            rel_line_to(cairo_ctx, legend.handle_length, 0)
            set_line_width(cairo_ctx, plot.line_width * ctx.width_scale)
            plot.line_style != :solid && set_dash(cairo_ctx, plot.dash)
            stroke(cairo_ctx)
            set_dash(cairo_ctx, Float64[])
        end

        # draw mark
        if plot isa LineSeries
            x = x2 + legend.handle_length / 2
            draw_mark(cairo_ctx, x, y2, plot.mark, plot.mark_size, plot.mark_color, plot.mark_stroke_color)
        end

        # draw label
        x = x2 + legend.handle_length + 2 * inner_pad
        y = y2

        set_source_rgb(cairo_ctx, 0, 0, 0)
        draw_text(cairo_ctx, x, y, plot.label, halign="left", valign="center", angle=0)
    end

end


function draw_background!(c::Chart, ctx::RenderContext)
    _draw_figure_background!(ctx, c.figure_frame, ctx.background)
end

function draw_contents!(c::Chart, ctx::RenderContext)
    cairo_ctx = ctx.cairo_ctx
    reset_matrix!(ctx)
    # draw canvas grid
    draw!(c, ctx, c.canvas)

    # draw axes
    draw!(c.xaxis, ctx)

    draw!(c.yaxis, ctx)

    # draw plots
    rectangle(cairo_ctx, c.canvas.frame.x, c.canvas.frame.y, c.canvas.frame.width, c.canvas.frame.height)
    Cairo.clip(cairo_ctx)

    # draw dataseries
    sorted = sort(c.dataseries, by=x -> x.order)
    for p in sorted
        draw!(c, ctx, p)
    end
    reset_clip(cairo_ctx)

    if !isempty(c.title_box.text)
        reset_matrix!(ctx)
        select_font_face(cairo_ctx, get_font(c.xaxis.font), Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL)
        set_font_size(cairo_ctx, _chart_title_font_size(c))
        set_source_rgb(cairo_ctx, 0.0, 0.0, 0.0)
        _draw_text_box!(ctx, c.title_box)
    end

    # draw overlay annotations before legend
    for item in c.overlay_items
        item isa Annotation || continue
        draw!(c, ctx, item)
    end

    for item in c.left_items
        cb = item::Colorbar
        draw!(c, ctx, cb)
    end
    for item in c.right_items
        cb = item::Colorbar
        draw!(c, ctx, cb)
    end
    for item in c.top_items
        cb = item::Colorbar
        draw!(c, ctx, cb)
    end
    for item in c.bottom_items
        cb = item::Colorbar
        draw!(c, ctx, cb)
    end

    # draw legend last
    if _chart_has_legend(c)
        draw!(c, ctx, c.legend)
    end
end


function add_annotation(c::Chart, a::Annotation)
    push!(c.annotations, a)
    push!(c.overlay_items, a)
    return a
end
