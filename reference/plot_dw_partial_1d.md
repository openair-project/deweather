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
  cols = "Set1",
  ylim = NULL,
  radial_wd = TRUE,
  ncol = NULL,
  nrow = NULL,
  plot = TRUE,
  progress = rlang::is_interactive()
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
  dependence profile, between 0 and 1. Default is `0.1` (10% of data).
  Ignored if `n` is specified.

- cols:

  Colours to use for plotting. See
  [`openair::openColours()`](https://openair-project.github.io/openair/reference/openColours.html).

- ylim:

  The limits of the y-axis. Passed to the `ylim` argument of
  [`ggplot2::coord_cartesian()`](https://ggplot2.tidyverse.org/reference/coord_cartesian.html)
  (or `rlim` of
  [`ggplot2::coord_radial()`](https://ggplot2.tidyverse.org/reference/coord_radial.html)
  if `radial_wd` is `TRUE`). The default, `NULL`, allows each partial
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

- plot:

  When `FALSE`, return a list of plot data instead of a plot.

- progress:

  Show a progress bar? Defaults to `TRUE` in interactive sessions.

## Value

A `ggplot2` object showing the partial dependence plot. If multiple
`vars` are specified, a `patchwork` assembly of plots will be returned.
If `plot = FALSE`, a named list of plot data will be returned instead.
