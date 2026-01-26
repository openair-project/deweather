# Use the 'best parameters' determined by [`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md) to build a Deweather Model

This function takes the output of
[`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md)
and uses the `best_params` defined within. This is a convenient wrapper
around
[`build_dw_model()`](https://openair-project.github.io/deweather/reference/build_dw_model.md)
if you have already run
[`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md)
and are broadly happy with the parameters it has chosen. That being
said, the `params` argument can be used to override specific
hyperparameters.

## Usage

``` r
finalise_tdw_model(tdw, data, params = list(), ..., .date = "date")
```

## Arguments

- tdw:

  A deweather tuning object created with
  [`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md).

- data:

  An input `data.frame` containing one pollutant column (defined using
  `pollutant`) and a collection of feature columns (defined using
  `vars`). This must be provided in addition to `tdw` as it is expected
  most users will have provided
  [`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md)
  with a sampled dataset.

- params:

  A named list. These parameters are used to override the `best_params`
  defined within `tdw`. For example, if the 'best' parameter for `trees`
  is 50, `params = list(trees = 100)` will set it to 100 instead. This
  also includes engine-specific parameters (e.g., `lambda` for the
  `xgboost` engine).

- ...:

  Not currently used. To add engine-specific models, add them to
  [`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md)
  and they will be picked up automatically, or use
  [`build_dw_model()`](https://openair-project.github.io/deweather/reference/build_dw_model.md)
  directly.

- .date:

  The name of the 'date' column which defines the air quality
  timeseries. Passed to
  [`append_dw_vars()`](https://openair-project.github.io/deweather/reference/append_dw_vars.md)
  if needed. Also used to extract the time zone of the data for later
  restoration if `trend` is used as a variable.

## See also

[`build_dw_model()`](https://openair-project.github.io/deweather/reference/build_dw_model.md)

## Author

Jack Davison
