# Plot diurnal changes, removing the effect of meteorology

This function calculates the diurnal profile of a pollutant with the
effect of meteorology removed. Its primary use is to compare two periods
to determine whether there has been a shift in diurnal profile e.g. due
to some intervention.

## Usage

``` r
diurnalGbm(
  input_data,
  vars = c("ws", "wd", "hour", "weekday"),
  pollutant = "nox",
  dates = c("01/01/2012", "31/12/2012", "31/12/2013"),
  ylab = "value",
  plot = TRUE
)
```

## Arguments

- input_data:

  A data frame to analyse.

- vars:

  The explanatory variables used in the model.

- pollutant:

  Name of the pollutant to apply meteorological normalisation to.

- dates:

  A vector of dates, length three. These dates are used to partition the
  data into two categories (before/after). The date format is UK e.g.
  `date = c("19/2/2005", "19/2/2007", "19/2/2010")`.

- ylab:

  Label for y-axis.

- plot:

  Should a plot be produced? `FALSE` can be useful when analysing data
  to extract plot components and plotting them in other ways.

## Value

Some data

## Author

David Carslaw
