using Test
using QuickCharts

limits = QuickCharts.compute_auto_limits([2.0, 2.0])
@test limits[1] < 2.0 < limits[2]
@test isapprox(limits[2] - 2.0, 2.0 - limits[1])

ax = QuickCharts.Axis(direction=:horizontal, limits=[1.0e4, 5.0e4], label="x")
QuickCharts.configure!(ax)
@test ax.tick_exponent == 4
@test !isempty(ax.exponent_box.text)
@test all(!occursin("10", lbl) for lbl in ax.tick_labels)
@test first(ax.ticks) == 1.0e4
@test last(ax.ticks) == 5.0e4

ay = QuickCharts.Axis(direction=:vertical, limits=[1.0e-5, 5.0e-5], label="y")
QuickCharts.configure!(ay)
@test ay.tick_exponent == -5
@test !isempty(ay.exponent_box.text)
@test first(ay.ticks) == 1.0e-5
@test last(ay.ticks) == 5.0e-5

ax_small = QuickCharts.Axis(direction=:horizontal, limits=[0.0, 3.1e-3], label="x", ticks=[0.0, 1.0e-3, 2.0e-3, 3.1e-3])
QuickCharts.configure!(ax_small)
@test ax_small.tick_exponent == -3
@test "3.1" in ax_small.tick_labels
@test !isempty(ax_small.exponent_box.text)

aint = QuickCharts.Axis(direction=:horizontal, limits=[1.0e4, 4.0e4], ticks=[1.0e4, 2.0e4, 3.0e4, 4.0e4])
QuickCharts.configure!(aint)
@test all(!occursin(".", lbl) for lbl in aint.tick_labels)

amanual = QuickCharts.Axis(direction=:horizontal, limits=[1.0e4, 3.0e4], ticks=[1.0e4, 2.0e4, 3.0e4], tick_labels=["A", "B", "C"])
QuickCharts.configure!(amanual)
@test amanual.tick_labels == ["A", "B", "C"]
@test isempty(amanual.exponent_box.text)

line_chart = Chart()
add_line(line_chart, [1.0e4, 2.0e4, 3.0e4], [1.0e-5, 2.0e-5, 3.0e-5]; label="scaled")
QuickCharts.configure!(line_chart)
@test line_chart.xaxis.tick_exponent == 4
@test line_chart.yaxis.tick_exponent == -5

endpoint_chart = Chart(xlimits=[0.0, 10.0], ylimits=[0.0, 10.0])
add_line(endpoint_chart, [0.0, 10.0], [0.0, 10.0]; label="diag")
QuickCharts.configure!(endpoint_chart)
@test endpoint_chart.xaxis.ticks[1] == 0.0
@test endpoint_chart.xaxis.ticks[end] == 10.0
@test endpoint_chart.yaxis.ticks[1] == 0.0
@test endpoint_chart.yaxis.ticks[end] == 10.0

bar_chart = Chart()
add_bar(bar_chart, [1.0, 2.0], [3.0, 4.0]; bar_base=-2.0, label="bars")
QuickCharts.configure!(bar_chart)
@test bar_chart.yaxis.limits[1] < -2.0
@test bar_chart.yaxis.limits[2] > 4.0

small_span = QuickCharts.Axis(direction=:horizontal, limits=[1.0e-10, 1.5e-10])
QuickCharts.configure!(small_span)
@test length(small_span.ticks) > 1
@test first(small_span.ticks) == 1.0e-10
@test last(small_span.ticks) == 1.5e-10

auto_uniform = QuickCharts.Axis(direction=:horizontal, limits=[0.0, 10.0], nticks=:auto)
QuickCharts.configure!(auto_uniform)
@test auto_uniform.ticks[1] == 0.0
@test auto_uniform.ticks[end] == 10.0
@test length(unique(round.(diff(auto_uniform.ticks); digits=8))) == 1

fixed_ticks = QuickCharts.Axis(direction=:horizontal, limits=[0.0, 10.0], nticks=7)
QuickCharts.configure!(fixed_ticks)
@test fixed_ticks.ticks == [0.0, 1.5, 3.0, 4.5, 6.0, 7.5, 9.0]
@test fixed_ticks.nticks == 6

hidden_ticks = QuickCharts.Axis(direction=:horizontal, limits=[0.0, 1.0], label="x", ticks=:none)
QuickCharts.configure!(hidden_ticks)
@test hidden_ticks.show_ticks == false
@test isempty(hidden_ticks.ticks)
@test isempty(hidden_ticks.tick_labels)
@test hidden_ticks.tick_length == 0.0

hidden_chart = Chart(xlimits=[0.0, 1.0], ylimits=[0.0, 1.0], xticks=:none, yticks=:none)
add_line(hidden_chart, [0.0, 1.0], [0.0, 1.0]; label="diag")
QuickCharts.configure!(hidden_chart)
@test hidden_chart.xaxis.show_ticks == false
@test hidden_chart.yaxis.show_ticks == false
@test isempty(hidden_chart.xaxis.ticks)
@test isempty(hidden_chart.yaxis.ticks)

cb_fig = Chart(xlimits=[0.0, 1.0], ylimits=[0.0, 1.0])
cb_auto = QuickCharts.Colorbar(location=:right, limits=[0.0, 10.0], bins=:auto)
QuickCharts.configure!(cb_fig, cb_auto)
@test cb_auto.axis.ticks[1] == 0.0
@test cb_auto.axis.ticks[end] == 10.0
@test length(unique(round.(diff(cb_auto.axis.ticks); digits=8))) == 1

cb_manual = QuickCharts.Colorbar(location=:right, limits=[0.0, 10.0], bins=:auto, ticks=[0.0, 3.0, 10.0])
QuickCharts.configure!(cb_fig, cb_manual)
@test cb_manual.axis.ticks == [0.0, 3.0, 10.0]

@test_throws ArgumentError QuickCharts.Axis(direction=:horizontal, limits=[0.0, 1.0], ticks=:none, tick_labels=["a"])
