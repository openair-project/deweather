# Create partial dependence plots for deweather models

Generates partial dependence plots to visualize the relationship between
predictor variables and model predictions. These plots show how the
predicted pollutant concentration changes as a function of one variable
while averaging over the effects of all other variables.

## Usage

``` r
plot_dw_partial_1d(
  dw,
  vars = NULL,
  intervals = 40L,
  group = NULL,
  group_intervals = 3L,
  show_conf_int = TRUE,
  show_rug = TRUE,
  n = NULL,
  prop = 0.01,
  cols = "tol",
  ylim = NULL,
  radial_wd = TRUE,
  ncol = NULL,
  nrow = NULL,
  ...,
  .plot = TRUE,
  .plot_engine = NULL,
  .progress = rlang::is_interactive()
)
```

## Arguments

- dw:

  A deweather model created with
  [`build_dw_model()`](https://openair-project.github.io/deweather/reference/build_dw_model.md).

- vars:

  Character. The name of the variable(s) to plot. Must be one of the
  variables used in the model. If `NULL`, all variables will be plotted
  in order of importance.

- intervals:

  The number of points for the partial dependence profile.

- group:

  Optional grouping variable to show separate profiles for different
  levels of another predictor. Must be one of the variables used in the
  model. Default is `NULL` (no grouping).

- group_intervals:

  The number of bins when the `group` variable is numeric.

- show_conf_int:

  Should the bootstrapped 95% confidence interval be shown? In
  `plot_dw_partial_1d()` these are shown using transparent ribbons (for
  numeric variables) and rectangles (for categorical variables).

- show_rug:

  Should a 'rug' (ticks along the x-axis) be shown which identifies the
  exact intervals for each parameter?

- n:

  The number of observations to use for calculating the partial
  dependence profile. If `NULL` (default), uses `prop` to determine the
  sample size.

- prop:

  The proportion of input data to use for calculating the partial
  dependence profile, between 0 and 1. Default is `0.01` (1% of input
  data). Ignored if `n` is specified.

- cols:

  Colours to use for plotting. See
  [`openair::openColours()`](https://openair-project.github.io/openair/reference/openColours.html).

- ylim:

  The limits of the y-axis. The default, `NULL`, allows each partial
  dependence panel to have its own y-axis scale.

- radial_wd:

  Should the `"wd"` (wind direction) variable be plotted on a radial
  axis? This can enhance interpretability, but makes it inconsistent
  with other variables which are plotted on cartesian coordinates.
  Defaults to `TRUE`.

- ncol, nrow:

  When more than one `vars` is defined, `ncol` and `nrow` define the
  dimensions of the grid to create. Setting both to be `NULL` creates a
  roughly square grid.

- ...:

  Not currently used.

- .plot:

  When `FALSE`, return a `data.frame` of plot data instead of a plot.

- .plot_engine:

  The plotting engine to use. One of `"ggplot2"`, which returns a static
  plot, or `"plotly"`, which returns a dynamic HTML plot.

- .progress:

  Show a progress bar? Defaults to `TRUE` in interactive sessions.

## Value

A `ggplot2` object showing the partial dependence plot. If multiple
`vars` are specified, a `patchwork` assembly of plots will be returned.
If `plot = FALSE`, a named list of plot data will be returned instead.

## Parallel Processing

This function supports parallel processing using the `{mirai}` package.
You will likely find that the performance of this function increases if
"daemons" are set. The greatest benefits will be seen if you spawn as
many daemons as you have cores on your machine, although one fewer than
the available cores is often a good rule of thumb.

    # set workers - once per session
    mirai::daemons(4)

    # run your function as normal
    tune_dw_model(aqroadside, "no2", tree_depth = c(5, 10))

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
plot_dw_partial_1d(dw)
} # }
```
