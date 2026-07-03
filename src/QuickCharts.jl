__precompile__()

"""
QuickCharts provides lightweight chart-oriented plotting primitives backed by
Cairo, including single charts, chart grids, annotations, legends, colors, and
math-aware text rendering.
"""
module QuickCharts

using Cairo
using FFMPEG
using LinearAlgebra
using Printf
import FreeTypeAbstraction

mutable struct QuickChartsException <: Exception
    message::String
end

Base.showerror(io::IO, e::QuickChartsException) = printstyled(io, "QuickChartsException: ", e.message, "\n", color = :red)

include("include.jl")

export cm, Color, Colormap, Chart, ChartGrid, DataSeries, LineSeries, BarSeries, ContourSeries, QuiverSeries, Legend, Colorbar, Annotation
export add_series, add_line, add_scatter, add_bar, add_contour, add_quiver, add_annotation, add_chart, add_frame
export lighten, darken, gray, render, save
export Figure, FigureComponent, Frame, TextBox, RenderContext, Canvas, Axis
export VideoBuilder
export draw!, draw_background!, draw_contents!
export reset_matrix!, set_local_matrix!, draw_text, get_font, draw_mark
export rgb, rgba, compute_auto_limits
export data2user, user2data

end
