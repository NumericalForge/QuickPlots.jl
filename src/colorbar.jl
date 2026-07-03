# This file is part of the QuickCharts.jl package. It is licensed under the MIT License.

const _colorbar_locations = (:none, :left, :right, :top, :bottom)

"""
    Colorbar(; kwargs...)

Configure a contour colorbar.

`location` controls where the colorbar is placed relative to the chart.
Supported values are `:none`, `:left`, `:right`, `:top`, and `:bottom`.
"""
mutable struct Colorbar <: FigureComponent
    location::Symbol
    colormap::Colormap
    axis::Union{Axis,Nothing}
    discrete::Bool
    levels::Vector{Float64}
    length_factor::Float64
    inner_sep::Float64
    width::Float64
    height::Float64
    thickness::Float64
    frame::Frame

    function Colorbar(;
        location::Symbol=:right,
        colormap=Colormap(:viridis),
        limits::AbstractVector{<:Real}=[0.0, 1.0],
        label::AbstractString="",
        font_size::Real=9.0,
        font::AbstractString="NewComputerModern",
        ticks::AbstractVector{<:Real}=Float64[],
        tick_labels::AbstractVector{<:AbstractString}=String[],
        tick_length::Real=3.0,
        bins::Union{Int,Symbol}=:auto,
        inner_sep::Real=3.0,
        length_factor::Real=1.0,
        discrete::Bool=false,
        levels::AbstractVector{<:Real}=Float64[],
    )
        location in _colorbar_locations || throw(ArgumentError("Colorbar location must be one of $(_colorbar_locations)"))
        length_factor > 0 || throw(ArgumentError("Colorbar length_factor must be positive"))
        font_size > 0 || throw(ArgumentError("Colorbar font_size must be positive"))
        length(limits) == 2 || throw(ArgumentError("Colorbar limits must contain exactly two values"))
        if bins isa Symbol
            bins == :auto || throw(ArgumentError("Colorbar bins must be a positive integer or :auto"))
        elseif bins isa Int
            bins > 0 || throw(ArgumentError("Colorbar bins must be positive"))
        else
            throw(ArgumentError("Colorbar bins must be a positive integer or :auto"))
        end
        discrete && length(levels) < 2 && throw(ArgumentError("Discrete colorbars require at least two levels"))

        resolved_colormap = colormap isa Symbol ? Colormap(colormap) : colormap
        resolved_levels = collect(float.(levels))
        discrete_ticks = isempty(ticks) && !isempty(resolved_levels) ? resolved_levels : collect(float.(ticks))

        axis = nothing
        if location != :none
            direction = location in (:left, :right) ? :vertical : :horizontal
            axis = Axis(
                direction=direction,
                location=location,
                limits=collect(float.(limits)),
                label=label,
                font_size=font_size,
                font=String(font),
                ticks=discrete_ticks,
                tick_labels=String.(tick_labels),
                tick_length=tick_length,
                nticks=bins,
                auto_nticks_target=6,
            )
        end

        return new(
            location,
            resolved_colormap,
            axis,
            discrete,
            resolved_levels,
            float(length_factor),
            float(inner_sep),
            0.0,
            0.0,
            0.0,
            Frame(),
        )
    end
end


function _colorbar_normalized_position(cb::Colorbar, value::Float64)
    vmin, vmax = cb.axis.limits
    if isapprox(vmin, vmax; atol=eps(Float64))
        return 0.0
    end
    return (value - vmin) / (vmax - vmin)
end


function _draw_continuous_colorbar_bar!(cairo_ctx::CairoContext, cb::Colorbar, bar_x::Float64, bar_y::Float64, bar_width::Float64, bar_height::Float64)
    fmin, fmax = cb.axis.limits
    if cb.location in (:left, :right)
        pat = pattern_create_linear(0.0, bar_y + bar_height, 0.0, bar_y)
    else
        pat = pattern_create_linear(bar_x, 0.0, bar_x + bar_width, 0.0)
    end

    for (stop, color) in zip(cb.colormap.stops, cb.colormap.colors)
        normalized_stop = round((stop - fmin) / (fmax - fmin), digits=8)
        pattern_add_color_stop_rgb(pat, normalized_stop, color...)
    end

    set_source(cairo_ctx, pat)
    rectangle(cairo_ctx, bar_x, bar_y, bar_width, bar_height)
    fill(cairo_ctx)
    return nothing
end


function _draw_discrete_colorbar_bar!(cairo_ctx::CairoContext, cb::Colorbar, bar_x::Float64, bar_y::Float64, bar_width::Float64, bar_height::Float64)
    for i in 1:(length(cb.levels) - 1)
        lower = cb.levels[i]
        upper = cb.levels[i + 1]
        midpoint = 0.5 * (lower + upper)
        set_source_rgb(cairo_ctx, cb.colormap(midpoint)...)

        start_t = _colorbar_normalized_position(cb, lower)
        end_t = _colorbar_normalized_position(cb, upper)

        if cb.location in (:left, :right)
            y_start = bar_y + bar_height * (1 - end_t)
            y_end = bar_y + bar_height * (1 - start_t)
            rectangle(cairo_ctx, bar_x, y_start, bar_width, y_end - y_start)
        else
            x_start = bar_x + bar_width * start_t
            x_end = bar_x + bar_width * end_t
            rectangle(cairo_ctx, x_start, bar_y, x_end - x_start, bar_height)
        end
        fill(cairo_ctx)
    end
    return nothing
end


function _draw_colorbar_bar!(cairo_ctx::CairoContext, cb::Colorbar, bar_x::Float64, bar_y::Float64, bar_width::Float64, bar_height::Float64)
    if cb.discrete
        _draw_discrete_colorbar_bar!(cairo_ctx, cb, bar_x, bar_y, bar_width, bar_height)
    else
        _draw_continuous_colorbar_bar!(cairo_ctx, cb, bar_x, bar_y, bar_width, bar_height)
    end
    return nothing
end


function configure!(fig::Figure, cb::Colorbar)
    cb.location == :none && return cb

    configure!(cb.axis)
    cb.thickness = 1.33 * cb.axis.font_size
    cb.inner_sep = cb.thickness

    if cb.location in (:left, :right)
        cb.height = cb.length_factor * (fig.height - 2 * fig.outerpad)
        cb.axis.height = cb.height
        cb.width = cb.inner_sep + cb.thickness + cb.axis.tick_length + cb.axis.width
    else
        cb.width = cb.length_factor * (fig.width - 2 * fig.outerpad)
        cb.axis.width = cb.width
        cb.height = cb.inner_sep + cb.thickness + cb.axis.tick_length + cb.axis.height
    end

    return cb
end


function draw!(::Figure, ctx::RenderContext, cb::Colorbar)
    cb.location == :none && return nothing

    cairo_ctx = ctx.cairo_ctx
    reset_matrix!(ctx)

    x0 = cb.frame.x
    y0 = cb.frame.y
    x1 = cb.frame.x + cb.frame.width
    y1 = cb.frame.y + cb.frame.height

    if cb.location == :right
        bar_x = x0 + cb.inner_sep
        bar_y = y0 + 0.5 * (cb.frame.height - cb.height)
        cb.axis.frame = Frame(bar_x + cb.thickness + cb.axis.tick_length, bar_y, cb.axis.width, cb.height)
        draw!(cb.axis, ctx)
        _draw_colorbar_bar!(cairo_ctx, cb, bar_x, bar_y, cb.thickness, cb.height)
    elseif cb.location == :left
        bar_x = x1 - cb.inner_sep - cb.thickness
        bar_y = y0 + 0.5 * (cb.frame.height - cb.height)
        cb.axis.frame = Frame(x0, bar_y, cb.axis.width, cb.height)
        draw!(cb.axis, ctx)
        _draw_colorbar_bar!(cairo_ctx, cb, bar_x, bar_y, cb.thickness, cb.height)
    elseif cb.location == :bottom
        bar_x = x0 + 0.5 * (cb.frame.width - cb.width)
        bar_y = y0 + cb.inner_sep
        cb.axis.frame = Frame(bar_x, bar_y + cb.thickness + cb.axis.tick_length, cb.width, cb.axis.height)
        draw!(cb.axis, ctx)
        _draw_colorbar_bar!(cairo_ctx, cb, bar_x, bar_y, cb.width, cb.thickness)
    else
        bar_x = x0 + 0.5 * (cb.frame.width - cb.width)
        bar_y = y1 - cb.inner_sep - cb.thickness
        cb.axis.frame = Frame(bar_x, y0, cb.width, cb.axis.height)
        draw!(cb.axis, ctx)
        _draw_colorbar_bar!(cairo_ctx, cb, bar_x, bar_y, cb.width, cb.thickness)
    end

    return nothing
end
