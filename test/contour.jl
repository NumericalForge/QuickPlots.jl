using Test
using QuickCharts

function _svg_rect_sizes(svg::AbstractString)
    sizes = Tuple{Float64,Float64}[]
    pattern = r"<path fill-rule=\"nonzero\" fill=\"rgb\([^\"]+\)\" fill-opacity=\"1\" d=\"M ([0-9.]+) ([0-9.]+) L ([0-9.]+) ([0-9.]+) L ([0-9.]+) ([0-9.]+) L ([0-9.]+) ([0-9.]+) Z M ([0-9.]+) ([0-9.]+) \"\/>"
    for m in eachmatch(pattern, svg)
        x1 = parse(Float64, m.captures[1])
        y1 = parse(Float64, m.captures[2])
        x2 = parse(Float64, m.captures[3])
        y2 = parse(Float64, m.captures[4])
        x3 = parse(Float64, m.captures[5])
        y3 = parse(Float64, m.captures[6])
        x4 = parse(Float64, m.captures[7])
        y4 = parse(Float64, m.captures[8])
        if isapprox(y1, y2) && isapprox(x2, x3) && isapprox(y3, y4) && isapprox(x4, x1)
            push!(sizes, (abs(x2 - x1), abs(y3 - y2)))
        end
    end
    return sizes
end

function _canvas_scale_ratio(chart::Chart)
    dx = chart.xaxis.limits[2] - chart.xaxis.limits[1]
    dy = chart.yaxis.limits[2] - chart.yaxis.limits[1]
    return chart.canvas.frame.width / dx, chart.canvas.frame.height / dy
end

function _frame_contains(outer::Frame, inner::Frame; atol::Float64=1.0e-8)
    return inner.x >= outer.x - atol &&
           inner.y >= outer.y - atol &&
           inner.x + inner.width <= outer.x + outer.width + atol &&
           inner.y + inner.height <= outer.y + outer.height + atol
end

@testset "Contour series" begin
    x = [0.0, 1.0]
    y = [0.0, 1.0]
    z = [0.0 1.0; 1.0 2.0]

    line_series = ContourSeries(x, y, z; levels=[1.0], label="diag")
    @test !line_series.filled
    @test !isempty(line_series.line_segments)
    @test isempty(line_series.fill_bands)
    @test line_series.color === :auto
    @test line_series.colormap.stops[1] < line_series.levels[1] < line_series.colormap.stops[end]
    @test sprint(show, line_series) == "ContourSeries(mode=:line, size=2x2, levels=1, label=\"diag\", order=0)"
    @test all(segment[1] == 1.0 for segment in line_series.line_segments)
    for (_, (x1, y1, x2, y2)) in line_series.line_segments
        @test isapprox(x1 + y1, 1.0; atol=1.0e-8)
        @test isapprox(x2 + y2, 1.0; atol=1.0e-8)
    end

    filled_series = ContourSeries(x, y, z; filled=true, levels=[0.0, 1.0, 2.0], colorbar=:right)
    @test filled_series.filled
    @test !isempty(filled_series.fill_bands)
    @test !isempty(filled_series.line_segments)
    @test filled_series.colormap.stops[1] ≈ 0.0
    @test filled_series.colormap.stops[end] ≈ 2.0

    filled_no_lines = ContourSeries(x, y, z; filled=true, levels=[0.0, 1.0, 2.0], line_style=:none)
    @test isempty(filled_no_lines.line_segments)

    @test_throws ArgumentError ContourSeries([0.0], y, z)
    @test_throws ArgumentError ContourSeries(x, [0.0], z)
    @test_throws ArgumentError ContourSeries(x, y, [0.0 1.0 2.0; 1.0 2.0 3.0])
    @test_throws ArgumentError ContourSeries([0.0, 0.0], y, z)
    @test_throws ArgumentError ContourSeries(x, [0.0, 0.0], z)
    @test_throws ArgumentError ContourSeries(x, y, z; nlevels=0)
    @test_throws ArgumentError ContourSeries(x, y, z; filled=true, levels=[1.0])
    @test_throws ArgumentError ContourSeries(x, y, z; colorbar=:bad)
    @test_throws ArgumentError ContourSeries(x, y, z; colorbar_ratio=0.0)

    hole_series = ContourSeries(
        [0.0, 1.0, 2.0],
        [0.0, 1.0, 2.0],
        [0.0 1.0 2.0; 1.0 NaN 3.0; 2.0 3.0 4.0];
        levels=[1.0, 2.0, 3.0],
        filled=true,
    )
    @test isempty(hole_series.fill_bands)
    @test isempty(hole_series.line_segments)

    raw_connected = QuickCharts._raw_contour_fill_polygons(
        [0.0, 1.0, 2.0],
        [0.0, 1.0],
        [0.0 0.5 1.0; 0.0 0.5 1.0],
        [0.0, 1.0],
    )
    merged_connected = QuickCharts._merge_contour_fill_polygons(raw_connected, [0.0, 1.0])
    @test length(raw_connected) > 1
    @test length(merged_connected) == 1
    @test length(merged_connected[1].polygons) == 1

    raw_disconnected = [
        (1, [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]),
        (1, [(2.0, 0.0), (3.0, 0.0), (3.0, 1.0), (2.0, 1.0)]),
    ]
    merged_disconnected = QuickCharts._merge_contour_fill_polygons(raw_disconnected, [0.0, 1.0])
    @test length(merged_disconnected) == 1
    @test length(merged_disconnected[1].polygons) == 2

    descending_series = ContourSeries(
        reverse([0.0, 1.0, 2.0]),
        [0.0, 1.0],
        reverse([0.0 0.5 1.0; 0.0 0.5 1.0]; dims=2);
        filled=true,
        levels=[0.0, 1.0],
    )
    @test !isempty(descending_series.fill_bands)
end

@testset "Contour charts" begin
    x = collect(range(-1, 1; length=11))
    y = collect(range(-1, 1; length=9))
    z = [xi + yi for yi in y, xi in x]

    chart = Chart(size=(8cm, 6cm), background=:white, xlabel="`x`", ylabel="`y`")
    add_contour(chart, x, y, z; levels=[-1.0, 0.0, 1.0], label="plane")
    QuickCharts.configure!(chart)
    @test chart.xaxis.limits[1] < minimum(x)
    @test chart.xaxis.limits[2] > maximum(x)
    @test chart.yaxis.limits[1] < minimum(y)
    @test chart.yaxis.limits[2] > maximum(y)
    @test length(chart.right_items) == 1
    @test chart.right_items[1] isa Colorbar
    @test chart.right_items[1].axis.label == "plane"
    @test chart.right_items[1].discrete == false
    @test chart.right_items[1].axis.ticks == [-1.0, 0.0, 1.0]
    @test chart.legend.frame.width == 0.0
    @test chart.legend.frame.height == 0.0

    no_colorbar_chart = Chart(size=(8cm, 6cm), background=:white, xlabel="`x`", ylabel="`y`")
    add_contour(no_colorbar_chart, x, y, z; levels=[-1.0, 0.0, 1.0], colorbar=:none)
    QuickCharts.configure!(no_colorbar_chart)
    @test chart.canvas.frame.y > no_colorbar_chart.canvas.frame.y
    @test chart.canvas.frame.height < no_colorbar_chart.canvas.frame.height

    filled_chart = Chart(size=(8cm, 6cm), background=:white)
    add_contour(filled_chart, x, y, z; filled=true, levels=[-1.0, 0.0, 1.0], colorbar=:right, label="first")
    add_contour(filled_chart, x, y, z .+ 0.25; filled=true, levels=[-0.75, 0.25, 1.25], colorbar=:right, label="second")
    QuickCharts.configure!(filled_chart)
    @test length(filled_chart.right_items) == 2
    @test filled_chart.legend.frame.width == 0.0
    @test filled_chart.legend.frame.height == 0.0
    first_cb = filled_chart.right_items[1]::Colorbar
    second_cb = filled_chart.right_items[2]::Colorbar
    @test first_cb.axis.label == "first"
    @test second_cb.axis.label == "second"
    @test first_cb.discrete == true
    @test second_cb.discrete == true
    @test first_cb.axis.ticks == [-1.0, 0.0, 1.0]
    @test second_cb.axis.ticks == [-0.75, 0.25, 1.25]
    @test first_cb.frame.y != second_cb.frame.y

    overlay_chart = Chart(size=(8cm, 6cm), background=:white)
    overlay = add_contour(overlay_chart, x, y, z; filled=true, levels=[-1.0, 0.0, 1.0], colorbar=:right)
    @test !isempty(overlay.fill_bands)
    @test !isempty(overlay.line_segments)

    no_line_overlay = add_contour(overlay_chart, x, y, z .+ 0.2; filled=true, levels=[-0.8, 0.2, 1.2], line_style=:none, colorbar=:left)
    @test isempty(no_line_overlay.line_segments)

    custom_tick_chart = Chart(size=(8cm, 6cm), background=:white)
    add_contour(
        custom_tick_chart,
        x,
        y,
        z;
        filled=true,
        levels=[-1.0, 0.0, 1.0],
        colorbar=:right,
        colorbar_ticks=[-1.0, 1.0],
        colorbar_tick_labels=["low", "high"],
    )
    QuickCharts.configure!(custom_tick_chart)
    custom_cb = custom_tick_chart.right_items[1]::Colorbar
    @test custom_cb.axis.ticks == [-1.0, 1.0]
    @test custom_cb.axis.tick_labels == ["low", "high"]

    nonuniform_chart = Chart(size=(8cm, 6cm), background=:white)
    add_contour(nonuniform_chart, x, y, z; filled=true, levels=[0.0, 0.5, 2.0, 5.0], colorbar=:right, colorbar_label="nonuniform")
    QuickCharts.configure!(nonuniform_chart)
    nonuniform_cb = nonuniform_chart.right_items[1]::Colorbar
    @test nonuniform_cb.discrete == true
    @test nonuniform_cb.axis.ticks == [0.0, 0.5, 2.0, 5.0]

    line_file = joinpath("output", "contour-lines.svg")
    filled_file = joinpath("output", "contour-filled.svg")
    filled_png = joinpath("output", "contour-filled.png")
    nonuniform_file = joinpath("output", "contour-nonuniform.svg")
    save(chart, line_file)
    save(filled_chart, filled_file, filled_png)
    save(nonuniform_chart, nonuniform_file)
    @test isfile(line_file)
    @test isfile(filled_file)
    @test isfile(filled_png)
    @test isfile(nonuniform_file)
    @test occursin("stroke-width=\"0.25\"", read(filled_file, String))

    filled_svg = read(filled_file, String)
    @test !occursin("<linearGradient", filled_svg)
    filled_rect_sizes = _svg_rect_sizes(filled_svg)
    @test count(size -> 10.0 < size[1] < 20.0 && size[2] > 20.0, filled_rect_sizes) >= 4

    nonuniform_svg = read(nonuniform_file, String)
    nonuniform_rect_sizes = _svg_rect_sizes(nonuniform_svg)
    colorbar_band_heights = [size[2] for size in nonuniform_rect_sizes if 10.0 < size[1] < 20.0 && size[2] > 5.0]
    @test length(colorbar_band_heights) >= 3
    @test length(unique(round.(colorbar_band_heights; digits=3))) > 1

    equal_right_chart = Chart(size=(8cm, 6cm), background=:white, aspect_ratio=:equal, xlimits=[0.0, 10.0], ylimits=[0.0, 10.0])
    add_contour(equal_right_chart, x, y, z; filled=true, levels=[-1.0, 0.0, 1.0], colorbar=:right)
    QuickCharts.configure!(equal_right_chart)
    sx_right, sy_right = _canvas_scale_ratio(equal_right_chart)
    @test isapprox(sx_right, sy_right; atol=1.0e-8)
    @test equal_right_chart.xaxis.limits == [0.0, 10.0]
    @test equal_right_chart.yaxis.limits == [0.0, 10.0]
    @test _frame_contains(QuickCharts._chart_plot_frame(equal_right_chart), equal_right_chart.canvas.frame)

    equal_left_chart = Chart(size=(8cm, 6cm), background=:white, aspect_ratio=:equal, xlimits=[0.0, 10.0], ylimits=[0.0, 10.0])
    add_contour(equal_left_chart, x, y, z; filled=true, levels=[-1.0, 0.0, 1.0], colorbar=:left)
    QuickCharts.configure!(equal_left_chart)
    sx_left, sy_left = _canvas_scale_ratio(equal_left_chart)
    @test isapprox(sx_left, sy_left; atol=1.0e-8)
    @test equal_left_chart.xaxis.limits == [0.0, 10.0]
    @test equal_left_chart.yaxis.limits == [0.0, 10.0]
    @test _frame_contains(QuickCharts._chart_plot_frame(equal_left_chart), equal_left_chart.canvas.frame)

    equal_top_chart = Chart(size=(8cm, 6cm), background=:white, aspect_ratio=:equal, xlimits=[0.0, 10.0], ylimits=[0.0, 10.0])
    add_contour(equal_top_chart, x, y, z; filled=true, levels=[-1.0, 0.0, 1.0], colorbar=:top)
    QuickCharts.configure!(equal_top_chart)
    sx_top, sy_top = _canvas_scale_ratio(equal_top_chart)
    @test isapprox(sx_top, sy_top; atol=1.0e-8)
    @test equal_top_chart.xaxis.limits == [0.0, 10.0]
    @test equal_top_chart.yaxis.limits == [0.0, 10.0]
    @test _frame_contains(QuickCharts._chart_plot_frame(equal_top_chart), equal_top_chart.canvas.frame)

    equal_bottom_chart = Chart(size=(8cm, 6cm), background=:white, aspect_ratio=:equal, xlimits=[0.0, 10.0], ylimits=[0.0, 10.0])
    add_contour(equal_bottom_chart, x, y, z; filled=true, levels=[-1.0, 0.0, 1.0], colorbar=:bottom)
    QuickCharts.configure!(equal_bottom_chart)
    sx_bottom, sy_bottom = _canvas_scale_ratio(equal_bottom_chart)
    @test isapprox(sx_bottom, sy_bottom; atol=1.0e-8)
    @test equal_bottom_chart.xaxis.limits == [0.0, 10.0]
    @test equal_bottom_chart.yaxis.limits == [0.0, 10.0]
    @test _frame_contains(QuickCharts._chart_plot_frame(equal_bottom_chart), equal_bottom_chart.canvas.frame)

    laplace_like_chart = Chart(size=(8cm, 7cm), background=:white, aspect_ratio=:equal, xlimits=[0.0, 10.0], ylimits=[0.0, 10.0], xticks=:none, yticks=:none)
    add_contour(laplace_like_chart, collect(range(0.0, 10.0; length=20)), collect(range(0.0, 10.0; length=20)), [xi + yi for yi in collect(range(0.0, 10.0; length=20)), xi in collect(range(0.0, 10.0; length=20))]; filled=true, levels=[0.0, 5.0, 10.0, 15.0, 20.0], colorbar=:right)
    QuickCharts.configure!(laplace_like_chart)
    sx_laplace, sy_laplace = _canvas_scale_ratio(laplace_like_chart)
    @test isapprox(sx_laplace, sy_laplace; atol=1.0e-8)
    @test laplace_like_chart.xaxis.limits == [0.0, 10.0]
    @test laplace_like_chart.yaxis.limits == [0.0, 10.0]
    @test _frame_contains(QuickCharts._chart_plot_frame(laplace_like_chart), laplace_like_chart.canvas.frame)
end
