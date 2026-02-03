# Visualise deweather model feature importance

Visualise the feature importance (% Gain for boosted tree models,
permutation importance for random forest models) for each variable of a
deweather model as a bar chart, with some customisation.

## Usage

``` r
plot_dw_importance(
  dw,
  aggregate_factors = FALSE,
  sort = TRUE,
  cols = "tol",
  ...,
  .plot = TRUE,
  .plot_engine = NULL
)
```

## Arguments

- dw:

  A deweather model created with
  [`build_dw_model()`](https://openair-project.github.io/deweather/reference/build_dw_model.md).

- aggregate_factors:

  Defaults to `FALSE`. If `TRUE`, the importance of factor inputs (e.g.,
  Weekday) will be summed into a single variable. This only applies to
  certain engines (e.g., `"xgboost"`) which report factor importance as
  disaggregate features.

- sort:

  If `TRUE`, the default, features will be sorted by their importance.
  If `FALSE`, they will be sorted alphabetically. In
  `plot_dw_importance()` this will change the ordering of the y-axis,
  whereas in
  [`get_dw_importance()`](https://openair-project.github.io/deweather/reference/getters-dw.md)
  it will change whether `var` is returned as a factor or character data
  type.

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

## Value

a
[ggplot2](https://ggplot2.tidyverse.org/reference/ggplot2-package.html)
figure

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
