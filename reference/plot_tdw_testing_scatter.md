# Plot Observed vs Modelled Scatter using the 'best parameters' from [`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md)

[`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md)
determines a 'best' set of parameters automatically and models some
'final' predictions using a reserved testing dataset to evaluate the
model. This function produces a scatter plot (or binned variant
thereof).

## Usage

``` r
plot_tdw_testing_scatter(
  tdw,
  method = c("scatter", "bin", "hexbin"),
  group = NULL,
  bins = 50L,
  show_ablines = TRUE,
  show_params = TRUE,
  cols = "viridis",
  cols_ablines = c("black", "grey50"),
  ...,
  .plot = TRUE,
  .plot_engine = NULL
)
```

## Arguments

- tdw:

  A deweather tuning object created with
  [`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md).

- method:

  One of `"scatter"`, `"bin"` or `"hexbin"`.

- group:

  A variable (one of the initial modelling parameters) to colour the
  scatter plot by. Only used when `method = "scatter"`. This could be
  useful to determine where the model is working most or least
  effectively, or to identify other patterns in the data.

- bins:

  The number of bins to use when `method = "bin"` or
  `method = "hexbin"`.

- show_ablines:

  Show 1:1, 2:1 and 1:2 lines to assist with model evaluation? Lines
  will appear beneath the "scatter" `method` and above either of the
  "bin" `method`s.

- show_params:

  Show an annotation of model parameters in the top-left corner of the
  scatter plot?

- cols:

  Colours to use for plotting. See
  [`openair::openColours()`](https://openair-project.github.io/openair/reference/openColours.html).

- cols_ablines:

  Colours to use for the diagonal lines, if `show_ablines = TRUE`. The
  the first colour is used for the 1:1 line, and the second for the 2:1
  and 1:2 lines. Passed to
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
engines. For example, hexagonal binning in `plot_tdw_testing_scatter()`
is supported in `ggplot2` but not in `plotly` at time of writing.

## See also

Other Model Tuning Functions:
[`plot_tdw_tuning_metrics()`](https://openair-project.github.io/deweather/reference/plot_tdw_tuning_metrics.md),
[`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md)

## Author

Jack Davison

## Examples

``` r
if (FALSE) { # \dontrun{
tdw <- tune_dw_model(aqroadside, "no2", trees = c(1, 5))
plot_tdw_testing_scatter(tdw)
} # }
```
