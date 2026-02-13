# Create a 2-way partial dependence plot for deweather models

Generates 2-way partial dependence plot to visualize the relationship
between two predictor variables and model predictions. These plots show
how the predicted pollutant concentration changes as a function of two
variables while averaging over the effects of all other variables.

## Usage

``` r
plot_dw_partial_2d(
  dw,
  var_x = NULL,
  var_y = NULL,
  intervals = 40L,
  contour = c("none", "lines", "fill"),
  contour_bins = 8,
  exclude_distance = 0.05,
  show_conf_int = FALSE,
  n = NULL,
  prop = 0.01,
  cols = "viridis",
  radial_wd = FALSE,
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

- var_x, var_y:

  The name of the two variables to plot. Must be one of the variables
  used in the model. If both are missing, the top two most individually
  important numeric variables will be selected automatically.

- intervals:

  The number of points for the partial dependence profile.

- contour:

  Show contour lines on the plot? Can be one of `"none"` (the default,
  no contour lines), `"lines"` (draws lines) or `"fill"` (draws filled
  contours using a binned colour scale).

- contour_bins:

  How many bins should be drawn if `contour != "none"`?

- exclude_distance:

  A 2-way partial dependence plot uses
  [`mgcv::exclude.too.far()`](https://rdrr.io/pkg/mgcv/man/exclude.too.far.html)
  to ensure the plotted surface is within range of the original input
  data. `exclude_distance` defines how far away from the original data
  is too far to plot. This should be in the range `0` to `1`, where
  higher values are more permissive; `1` will retain all data.

- show_conf_int:

  Should the bootstrapped 95% confidence interval be shown? In
  `plot_dw_partial_2d()` this creates separate facets for the lower and
  higher confidence intervals. It may be easiest to see the difference
  by using `contour = "fill"`.

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

- radial_wd:

  Should the `"wd"` (wind direction) variable be plotted on a radial
  axis? This can enhance interpretability, but makes it inconsistent
  with other variables which are plotted on cartesian coordinates.
  Defaults to `FALSE`.

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

A `ggplot2` object showing the partial dependence plot. If
`plot = FALSE`, a named list of plot data will be returned instead.

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
