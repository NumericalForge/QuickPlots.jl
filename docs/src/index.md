```@meta
DocTestSetup = quote
    using QuickCharts
end
```

# QuickCharts.jl

`QuickCharts.jl` provides chart-focused plotting primitives for building publication-ready figures:

- `Chart` for line, scatter, bar, contour, and quiver plots.
- `ChartGrid` for multi-panel layouts.
- `VideoBuilder` for frame-by-frame animation export.
- `Annotation`, `Legend`, `Colorbar`, `Color`, `Colormap`, and math-aware text rendering utilities.

The package centers on a small plotting surface: single charts, chart grids, videos, legends, annotations, colors, colormaps, and math-aware labels.

`Chart` and `ChartGrid` also support inline display in rich Julia environments such as VS Code and notebooks. Use `save(...)` when you want persistent output files such as `.svg`, `.pdf`, `.png`, `.ps`, `.mp4`, or `.avi`.

## Installation

```julia
using Pkg
Pkg.add("QuickCharts")
```

## Documentation Map

The docs are organized in two parts:

1. `Manual`: package setup and tutorials for charts, field plots, and multi-panel layouts.
2. `API Reference`: exported plotting types and functions.
