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
  prop = 0.05,
  cols = "viridis",
  radial_wd = FALSE,
  plot = TRUE,
  progress = rlang::is_interactive()
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
  dependence profile, between 0 and 1. Default is `0.1` (10% of data).
  Ignored if `n` is specified.

- cols:

  Colours to use for plotting. See
  [`openair::openColours()`](https://openair-project.github.io/openair/reference/openColours.html).

- radial_wd:

  Should the `"wd"` (wind direction) variable be plotted on a radial
  axis? This can enhance interpretability, but makes it inconsistent
  with other variables which are plotted on cartesian coordinates.
  Defaults to `FALSE`.

- plot:

  When `FALSE`, return a list of plot data instead of a plot.

- progress:

  Show a progress bar? Defaults to `TRUE` in interactive sessions.

## Value

A `ggplot2` object showing the partial dependence plot. If
`plot = FALSE`, a named list of plot data will be returned instead.
