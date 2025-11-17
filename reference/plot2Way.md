# Plot two-way interactions from gbm model

Plot two-way interactions from gbm model

## Usage

``` r
plot2Way(
  dw_model,
  variable = c("ws", "air_temp"),
  res = 100,
  exclude = TRUE,
  cols = "default",
  dist = 0.05,
  plot = TRUE,
  ...
)
```

## Arguments

- dw_model:

  Model object from running
  [`buildMod()`](https://openair-project.github.io/deweather/reference/buildMod.md).

- variable:

  The variables to plot. Must be of length two e.g.
  `variables = c("ws", "wd")`.

- res:

  Resolution in x-y, i.e., number of points in each dimension.

- exclude:

  Should surfaces exclude predictions too far from original data? The
  default is `TRUE`.

- cols:

  Colours to be used for plotting, passed to
  [`openair::openColours()`](https://openair-project.github.io/openair/reference/openColours.html).

- dist:

  When plotting surfaces, `dist` controls how far from the original data
  the predictions should be made. See `exclude.too.far` from the `mgcv`
  package. Data are first transformed to a unit square. Values should be
  between `0` and `1`.

- plot:

  Should a plot be produced? `FALSE` can be useful when analysing data
  to extract plot components and plotting them in other ways.

- ...:

  Other arguments to be passed for plotting.

## Value

To add

## See also

Other deweather model plotting functions:
[`plotInfluence()`](https://openair-project.github.io/deweather/reference/plotInfluence.md),
[`plotPD()`](https://openair-project.github.io/deweather/reference/plotPD.md)

## Author

David Carslaw
