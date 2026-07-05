# QuickCharts.jl


[![docs-stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://numericalforge.github.io/QuickCharts.jl/stable/)
[![docs-dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://numericalforge.github.io/QuickCharts.jl/dev/)


`QuickCharts.jl` is a lightweight Julia package for chart-oriented plotting
with Cairo output, including line, scatter, bar, contour, and quiver plots.

It focuses on a compact set of figure-building tools: `Chart` for single plots, `ChartGrid` for composed layouts, `VideoBuilder` for frame-by-frame video export, and supporting types for colors, legends, annotations, and math-aware text rendering.

Highlights include:

- Named colors with underscore-free aliases such as `:royal_blue` and `:royalblue`.
- Color utilities such as `lighten`, `darken`, and built-in colormaps including `:viridis` and `:magma`.
- File export to `.pdf`, `.png`, `.svg`, `.ps`, plus `.mp4` and `.avi` video generation.

![QuickCharts showcase](docs/src/assets/readme-showcase.svg)

## Installation

Install `QuickCharts.jl` from Julia's General registry:

```julia
using Pkg
Pkg.add("QuickCharts")
```

## Quick Start

```julia
using QuickCharts

x = collect(0:0.2:2π)
chart = Chart(
    size = (10cm, 7cm),
    title = "Trigonometric Curves",
    xlabel = "`x`",
    ylabel = "`y`",
    legend = :bottom_right,
)

add_line(chart, x, sin.(x); label = "`sin(x)`", mark = :circle)
add_line(chart, x, cos.(x); label = "`cos(x)`", color = lighten(:royalblue, 0.15))

save(chart, "chart.svg", "chart.pdf")
```

## Video Export

```julia
using QuickCharts

x = collect(range(0, 2π; length = 120))
video = VideoBuilder(framerate = 12, freeze_scale = true, bounds_factor = 1.05)

for phase in range(0, 2π; length = 18)
    frame = Chart(
        size = (10cm, 7cm),
        title = "Phase Shift",
        xlabel = "`x`",
        ylabel = "`y`",
        legend = :top_right,
        background = :white,
    )

    add_line(frame, x, sin.(x .+ phase); color = :royalblue, label = "`sin(x + ϕ)`")
    add_line(frame, x, cos.(x .+ phase); color = Colormap(:viridis)(0.75), label = "`cos(x + ϕ)`")
    add_frame(video, frame)
end

save(video, "phase-shift.mp4")
```

Set `freeze_scale=true` when you want all frames to reuse the view from frame 1.
Use `bounds_factor>1` to add extra space around that frozen view.

## Documentation

Online documentation is available at:

https://numericalforge.github.io/QuickCharts.jl/dev/


## License

This project is licensed under the MIT License. See [LICENSE.md](LICENSE.md) for details.
