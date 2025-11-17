# Plot a GBM influence plot

Plot a GBM influence plot

## Usage

``` r
plotInfluence(dw_model, col = "grey30", sort = TRUE)
```

## Arguments

- dw_model:

  Model object from running
  [`buildMod()`](https://openair-project.github.io/deweather/reference/buildMod.md).

- col:

  Colour to use to use to colour the bars. Alternatively, users can
  provide `"var"` which will colour each bar differently, or `"mean"`
  which will colour each bar by its mean relative variable influence.

- sort:

  Sort the variables by their relative variable influences? Defaults to
  `TRUE`. `FALSE` displays them alphabetically.

## Value

Plot

## See also

Other deweather model plotting functions:
[`plot2Way()`](https://openair-project.github.io/deweather/reference/plot2Way.md),
[`plotPD()`](https://openair-project.github.io/deweather/reference/plotPD.md)

## Author

David Carslaw
