# Plot a simulated 'deweathered' trend, optionally with its input data

This function conveniently plots the trend from a simulated deweathered
time series, with the option to overlay the trend from the original
input data. The data can also be averaged over specified time intervals
for clearer visualisation.

## Usage

``` r
plot_sim_trend(
  sim,
  dw = NULL,
  avg.time = NULL,
  ylim = NULL,
  names = c("Met Simulation", "Original Data"),
  cols = "tol",
  ...,
  .plot = TRUE,
  .plot_engine = NULL
)
```

## Arguments

- sim:

  The output of
  [`simulate_dw_met()`](https://openair-project.github.io/deweather/reference/simulate_dw_met.md);
  a `data.frame` with first column `date` and second column a numeric
  pollutant.

- dw:

  Optionally, the input model used to construct `sim`. If provided, the
  original timeseries will be plotted alongside the simulated trend for
  easy comparison.

- avg.time:

  Passed to
  [`openair::timeAverage()`](https://openair-project.github.io/openair/reference/timeAverage.html).

- ylim:

  The limits of the y-axis.

- names:

  A character vector of length two, used to label the simulated dataset
  and the original dataset.

- cols:

  Colours to use for plotting. See
  [`openair::openColours()`](https://openair-project.github.io/openair/reference/openColours.html).

- ...:

  Not currently used.

- .plot:

  When `FALSE`, return a `data.frame` of plot data instead of a plot.

- .plot_engine:

  The plotting engine to use. One of `"ggplot2"`, which returns a static
  plot, or `"plotly"`, which returns a dynamic HTML plot.

## Plotting Engines

`deweather` offers different plotting engines for different purposes. At
the moment, two plotting engines are supported:

- `"ggplot2"`, for static plotting. This engine produces plots which can
  be easily saved to a `.png`, `.svg`, or other 'static' file format. To
  save a `ggplot2` plot, it is recommended to use the
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
  function.

- `"plotly"`, for dynamic plotting. This engine produces HTML plots
  which are suitable for embedding into `quarto` or `rmarkdown`
  documents, or for use in `shiny` applications. These can be saved
  using functions like
  [`htmlwidgets::saveWidget()`](https://rdrr.io/pkg/htmlwidgets/man/saveWidget.html).

The plotting engine is defined using the `.plot_engine` argument in any
`plot_*` function in `deweather`.

    # use default
    plot_dw_importance(dw)

    # set to ggplot2 (static)
    plot_dw_importance(dw, .plot_engine = "ggplot2")

    # set to plotly (HTML)
    plot_dw_importance(dw, .plot_engine = "plotly")

When `.plot_engine` is not set, the engine defaults to `"ggplot2"`.
However, this option can be overridden by using the
`deweather.plot_engine` global option.

    # set once per session
    options("deweather.plot_engine" = "plotly")

    # now defaults to "plotly" over "ggplot2"
    plot_dw_importance(dw)

Note that not all arguments in a function may apply to all plotting
engines. For example, hexagonal binning in
[`plot_tdw_testing_scatter()`](https://openair-project.github.io/deweather/reference/plot_tdw_testing_scatter.md)
is supported in `ggplot2` but not in `plotly` at time of writing.

## Author

Jack Davison

## Examples

``` r
if (FALSE) { # \dontrun{
dw <- build_dw_model(aqroadside, "no2")
sim <- simulate_dw_met(dw)
plot_sim_trend(sim, dw, avg.time = "month")
} # }
```
