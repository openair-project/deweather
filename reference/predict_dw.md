# Use a deweather model to predict with a new dataset

This function is a convenient wrapper around
[`parsnip::predict.model_fit()`](https://parsnip.tidymodels.org/reference/predict.model_fit.html)
to use a deweather model for prediction. This automatically extracts
relevant parts of the deweather object and creates variables within
`newdata` using
[`append_dw_vars()`](https://openair-project.github.io/deweather/reference/append_dw_vars.md)
if required.

## Usage

``` r
predict_dw(
  dw,
  newdata = deweather::get_dw_input_data(dw),
  name = deweather::get_dw_pollutant(dw),
  column_bind = FALSE
)
```

## Arguments

- dw:

  A deweather model created with
  [`build_dw_model()`](https://openair-project.github.io/deweather/reference/build_dw_model.md).

- newdata:

  Data set to which to apply the model. If missing the data used to
  build the model in the first place will be used.

- name:

  The name of the new column.

- column_bind:

  If `TRUE`, this function will return `newdata` with an additional
  prediction column bound to it. If `FALSE`, return a single-column data
  frame.

## Value

a [tibble](https://tibble.tidyverse.org/reference/tibble-package.html)

## Author

Jack Davison

## Examples

``` r
if (FALSE) { # \dontrun{
dw <- build_dw_model(aqroadside, "no2")
pred <- predict_dw(dw)
} # }
```
