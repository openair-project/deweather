# Conveniently append common 'deweathering' variables to an air quality time series

This function conveniently manipulates a datetime ('POSIXct') column (by
default named 'date') into a series of columns which are useful features
in deweather models. Used internally by
[`build_dw_model()`](https://openair-project.github.io/deweather/reference/build_dw_model.md)
and
[`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md),
but can be used directly by users if desired.

## Usage

``` r
append_dw_vars(
  data,
  vars = c("trend", "hour", "weekday", "weekend", "yday", "week", "month"),
  abbr = TRUE,
  ...,
  .date = "date"
)
```

## Arguments

- data:

  An input `data.frame` with at least one date(time) column.

- vars:

  A character vector of variables of interest. Possible options
  include: - `"trend"`: a numeric expression of the overall time
  series - `"hour"`: the hour of the day (0-23) - `"weekday"`: the day
  of the week (Sunday through Saturday) - `"weekend"`: whether it is a
  weekend (Saturday, Sunday) or weekday - `"yday"`: the day of the
  year - `"week"`: the week of the year - `"month"`: the month of the
  year

- abbr:

  Abbreviate weekday and month strings? Defaults to `TRUE`, which tends
  to look better in plots.

- ...:

  Not currently used.

- .date:

  The name of the 'date' column to use for manipulation.

## See also

[`openair::cutData()`](https://openair-project.github.io/openair/reference/cutData.html)
for more flexible time series data conditioning.
