# Visualise deweather model feature importance

Visualise the feature importance (% Gain for boosted tree models) for
each variable of a deweather model, with some customisation.

## Usage

``` r
plot_dw_importance(dw, aggregate_factors = FALSE, sort = TRUE, cols = "tol")
```

## Arguments

- dw:

  A deweather model created with
  [`build_dw_model()`](https://openair-project.github.io/deweather/reference/build_dw_model.md).

- aggregate_factors:

  Defaults to `FALSE`. If `TRUE`, the importance of factor inputs (e.g.,
  Weekday) will be summed into a single variable. This only applies to
  certain engines which report factor importance as disaggregate
  features.

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

## Value

a
[ggplot2](https://ggplot2.tidyverse.org/reference/ggplot2-package.html)
figure
