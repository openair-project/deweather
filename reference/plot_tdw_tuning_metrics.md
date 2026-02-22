# Plot Tuning Metrics from [`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md)

This function creates a plot of the tuning metrics from a
`TuneDeweather` object created using
[`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md).
It visualises how different hyperparameter values affect model
performance (RMSE and RSQ). This allows for the 'best' parameters to be
refined through visual inspection. This plot is likely most effective
with between 1 and 3 simultaneously tuned parameters; any more will
impede plot interpretation.

## Usage

``` r
plot_tdw_tuning_metrics(
  tdw,
  x = NULL,
  group = NULL,
  facet = NULL,
  show_std_err = TRUE,
  cols = "tol",
  ...,
  .plot = TRUE,
  .plot_engine = NULL
)
```

## Arguments

- tdw:

  A deweather tuning object created with
  [`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md).

- x:

  The tuned parameter to plot on the x-axis. If not selected, the first
  parameter in the `metrics` dataset will be chosen.

- group, facet:

  Additional tuned parameters other than `x`, used to further control
  the plot. `group` colours the plot by another parameter, and `facet`
  splits the diagram into additional panels. Neither `group` nor `facet`
  can be the same parameter as `x`.

- show_std_err:

  Show the standard error using error bars?

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

## See also

Other Model Tuning Functions:
[`plot_tdw_testing_scatter()`](https://openair-project.github.io/deweather/reference/plot_tdw_testing_scatter.md),
[`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md)

## Author

Jack Davison

## Examples

``` r
if (FALSE) { # \dontrun{
tdw <- tune_dw_model(aqroadside, "no2", trees = c(1, 5))
plot_tdw_tuning_metrics(tdw)
} # }
```
