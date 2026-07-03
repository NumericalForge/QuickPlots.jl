# This file is part of the QuickCharts.jl package. It is licensed under the MIT License.

function _show_quoted(io::IO, value::AbstractString)
    return show(io, String(value))
end

function Base.show(io::IO, series::LineSeries)
    print(io, "LineSeries(")
    print(io, "n=", length(series.X))
    if !isempty(series.label)
        print(io, ", label=")
        _show_quoted(io, series.label)
    end
    print(io, ", style=")
    show(io, series.line_style)
    print(io, ", mark=")
    show(io, series.mark)
    print(io, ", order=", series.order)
    print(io, ")")
    return nothing
end

function Base.show(io::IO, series::BarSeries)
    print(io, "BarSeries(")
    print(io, "n=", length(series.X))
    if !isempty(series.label)
        print(io, ", label=")
        _show_quoted(io, series.label)
    end
    print(io, ", line_width=", series.line_width)
    print(io, ", order=", series.order)
    print(io, ")")
    return nothing
end

function Base.show(io::IO, series::QuiverSeries)
    print(io, "QuiverSeries(")
    print(io, "n=", length(series.X))
    if !isempty(series.label)
        print(io, ", label=")
        _show_quoted(io, series.label)
    end
    print(io, ", order=", series.order)
    print(io, ")")
    return nothing
end

function Base.show(io::IO, series::ContourSeries)
    print(io, "ContourSeries(")
    print(io, "mode=")
    show(io, series.filled ? :filled : :line)
    print(io, ", size=", length(series.y), "x", length(series.x))
    print(io, ", levels=", length(series.levels))
    if !isempty(series.label)
        print(io, ", label=")
        _show_quoted(io, series.label)
    end
    print(io, ", order=", series.order)
    print(io, ")")
    return nothing
end

Base.show(io::IO, ::MIME"text/plain", series::DataSeries) = show(io, series)

function Base.show(io::IO, chart::Chart)
    print(io, "Chart(size=", chart.width, " x ", chart.height, " pt")
    if !isempty(chart.title_box.text)
        print(io, ", title=")
        _show_quoted(io, chart.title_box.text)
    end
    print(io, ", axes=")
    _show_quoted(io, chart.xaxis.label)
    print(io, " vs ")
    _show_quoted(io, chart.yaxis.label)
    print(io, ", series=", length(chart.dataseries))
    print(io, ", annotations=", length(chart.annotations))
    print(io, ", legend=")
    show(io, chart.legend.location)
    print(io, ")")
    return nothing
end

Base.show(io::IO, ::MIME"text/plain", chart::Chart) = show(io, chart)

function Base.show(io::IO, grid::ChartGrid)
    if grid.auto_size && grid.width == 0 && grid.height == 0
        print(io, "ChartGrid(size=auto")
    else
        print(io, "ChartGrid(size=", grid.width, " x ", grid.height, " pt")
    end
    if !isempty(grid.title_box.text)
        print(io, ", title=")
        _show_quoted(io, grid.title_box.text)
    end
    print(io, ", layout=", grid.nrows, " x ", grid.ncols)
    print(io, ", children=", length(grid.children))
    print(io, ", column_headers=", length(grid.column_header_boxes))
    print(io, ", row_headers=", length(grid.row_header_boxes))
    print(io, ")")
    return nothing
end

Base.show(io::IO, ::MIME"text/plain", grid::ChartGrid) = show(io, grid)
