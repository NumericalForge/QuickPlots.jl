using Test
using QuickCharts

@testset "Quiver series" begin
    series = QuiverSeries([0.0, 1.0], [0.0, 1.0], [1.0, 0.0], [0.0, 1.0]; label="flow")
    @test series.color == Color(:black)
    @test series.line_width == 0.5
    @test series.max_length == 12.0
    @test series.head_length == 4.0
    @test sprint(show, series) == "QuiverSeries(n=2, label=\"flow\", order=0)"

    custom = QuiverSeries([0.0], [0.0], [1.0], [0.0]; color=:royal_blue, line_width=0.75, max_length=10.0, head_length=3.0)
    @test custom.color == Color(:royal_blue)
    @test custom.line_width == 0.75
    @test custom.max_length == 10.0
    @test custom.head_length == 3.0

    @test_throws ArgumentError QuiverSeries([0.0], [0.0, 1.0], [1.0], [0.0])
    @test_throws ArgumentError QuiverSeries([0.0], [0.0], [1.0], [0.0]; line_width=0.0)
    @test_throws ArgumentError QuiverSeries([0.0], [0.0], [1.0], [0.0]; max_length=0.0)
    @test_throws ArgumentError QuiverSeries([0.0], [0.0], [1.0], [0.0]; head_length=0.0)
    @test_throws ArgumentError QuiverSeries([0.0], [0.0], [1.0], [0.0]; color=:auto)
end

@testset "Quiver charts" begin
    chart = Chart(size=(8cm, 6cm), background=:white)
    attached = add_quiver(chart, [0.0, 1.0, 2.0], [0.0, 0.5, 1.0], [1.0, 2.0, 3.0], [0.0, 0.0, 0.0]; label="vectors")
    @test attached.color == Color(:black)
    @test attached.order == 1

    custom = add_quiver(chart, [0.0, 1.0], [1.0, 0.0], [0.5, 0.5], [0.5, -0.5]; color=:green, stride=2)
    @test custom.color == Color(:green)
    @test length(custom.X) == 1

    x = [0.0, 1.0, 2.0]
    y = [0.0, 1.0]
    U = [1.0 2.0 3.0; 4.0 5.0 6.0]
    V = [0.0 1.0 0.0; -1.0 0.0 1.0]

    grid_chart = Chart(size=(8cm, 6cm), background=:white)
    grid_series = add_quiver(grid_chart, x, y, U, V; stride=1, label="grid")
    @test length(grid_series.X) == 6
    @test grid_series.X == [0.0, 1.0, 2.0, 0.0, 1.0, 2.0]
    @test grid_series.Y == [0.0, 0.0, 0.0, 1.0, 1.0, 1.0]
    @test grid_series.U == [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
    @test grid_series.V == [0.0, 1.0, 0.0, -1.0, 0.0, 1.0]

    stride_series = add_quiver(grid_chart, x, y, U, V; stride=2)
    @test length(stride_series.X) == 2
    @test stride_series.X == [0.0, 2.0]
    @test stride_series.Y == [0.0, 0.0]

    tuple_stride_series = add_quiver(grid_chart, x, y, U, V; stride=(2, 1))
    @test length(tuple_stride_series.X) == 4
    @test tuple_stride_series.X == [0.0, 2.0, 0.0, 2.0]
    @test tuple_stride_series.Y == [0.0, 0.0, 1.0, 1.0]

    @test_throws ArgumentError add_quiver(grid_chart, x, y, U[:, 1:2], V)
    @test_throws ArgumentError add_quiver(grid_chart, x, y, U, V[:, 1:2])
    @test_throws ArgumentError add_quiver(grid_chart, x, y, U, V; stride=0)
    @test_throws ArgumentError add_quiver(grid_chart, x, y, U, V; stride=(0, 1))
    @test_throws ArgumentError add_quiver(chart, [0.0], [0.0], [1.0], [0.0]; stride=(1, 1))

    auto_chart = Chart(size=(8cm, 6cm), background=:white)
    add_quiver(auto_chart, [0.0, 1.0], [0.0, 1.0], [100.0, 200.0], [0.0, 0.0])
    QuickCharts.configure!(auto_chart)
    @test auto_chart.xaxis.limits[1] < 0.0
    @test auto_chart.xaxis.limits[2] < 2.0
    @test auto_chart.yaxis.limits[1] < 0.0
    @test auto_chart.yaxis.limits[2] < 2.0

    render_chart = Chart(size=(8cm, 6cm), background=:white, legend=:top_right)
    z = [xi + yi for yi in y, xi in x]
    add_contour(render_chart, x, y, z; filled=true, levels=[0.0, 1.5, 3.0], line_style=:none, colorbar=:none)
    add_quiver(render_chart, x, y, U, V; stride=1, label="flux")
    add_quiver(render_chart, [1.0, 2.0], [0.0, 1.0], [0.0, NaN], [0.0, 1.0]; color=:red)

    svg_file = joinpath("output", "quiver.svg")
    png_file = joinpath("output", "quiver.png")
    save(render_chart, svg_file, png_file)
    @test isfile(svg_file)
    @test isfile(png_file)
    @test occursin("<svg", read(svg_file, String))
end
