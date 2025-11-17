# Function to plot partial dependence plots with bootstrap uncertainties

Function to plot partial dependence plots with bootstrap uncertainties

## Usage

``` r
plotPD(
  dw_model,
  variable = "all",
  intervals = 40,
  ylim = NULL,
  ylab = NULL,
  col = "tomato",
  nrow = NULL,
  polar.wd = FALSE,
  auto.text = TRUE,
  plot = TRUE
)
```

## Arguments

- dw_model:

  Model object from running
  [`buildMod()`](https://openair-project.github.io/deweather/reference/buildMod.md).

- variable:

  The variable(s) to plot. Defaults to `"all"`, which plots all
  variables.

- intervals:

  Number of intervals to to calculate partial dependence over.

- ylim:

  user-specified `ylim`.

- ylab:

  y-axis label. By default this is the pollutant name.

- col:

  Colour for the panels. Passed to
  [`openair::openColours()`](https://openair-project.github.io/openair/reference/openColours.html).

- nrow:

  Number of rows for the plots.

- polar.wd:

  Plot the any wind direction components, labelled "wd", on a polar
  axis? Defaults to `FALSE`.

- auto.text:

  Either `TRUE` (default) or `FALSE`. If `TRUE` titles and axis labels
  will automatically try and format pollutant names and units properly,
  e.g., by subscripting the "2" in "NO2".

- plot:

  Should a plot be produced? `FALSE` can be useful when analysing data
  to extract plot components and plotting them in other ways.

## Value

Invisibly returns a list containing the plot, `plot`, a list of
individual plots, `panels`, and a list of the data used to create them,
`data`. `plot` is a
[patchwork](https://patchwork.data-imaginist.com/reference/patchwork-package.html)
object, so can be further manipulated using `&` and
[ggplot2](https://ggplot2.tidyverse.org/reference/ggplot2-package.html).

## See also

Other deweather model plotting functions:
[`plot2Way()`](https://openair-project.github.io/deweather/reference/plot2Way.md),
[`plotInfluence()`](https://openair-project.github.io/deweather/reference/plotInfluence.md)

## Author

David Carslaw
