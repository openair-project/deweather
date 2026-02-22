# Getters for various deweather tuning object features

`deweather` provides multiple 'getter' functions for extracting relevant
model features from a deweather model and/or tuning objects. These are a
useful convenience, particularly in conjunction with R's
[pipe](https://rdrr.io/r/base/pipeOp.html) operator (`|>`).

## Usage

``` r
get_tdw_pollutant(tdw)

get_tdw_vars(tdw)

get_tdw_engine(tdw)

get_tdw_best_params(tdw, param = NULL)

get_tdw_tuning_metrics(tdw, metric = NULL)

get_tdw_testing_metrics(tdw, metric = NULL)

get_tdw_testing_data(tdw)
```

## Arguments

- tdw:

  A deweather tuning object created with
  [`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md).

- param:

  For
  [`get_dw_params()`](https://openair-project.github.io/deweather/reference/getters-dw.md)
  and `get_tdw_best_params()`. The default (`NULL`) returns a list of
  model parameters. `param` will return one specific parameter as a
  character vector.

- metric:

  For `get_tdw_tuning_metrics()` and `get_tdw_testing_metrics()`. The
  default (`NULL`) returns a complete set of model parameters. `metric`
  will return one specific parameter. `metric` must be one of the
  [`openair::aqStats()`](https://openair-project.github.io/openair/reference/aqStats.html)
  metrics for `get_tdw_tuning_metrics()` and one of `"rmse"` or `"rsq"`
  for `get_tdw_testing_metrics()`.

## Value

Typically a character vector, except:

- `get_tdw_testing_metrics()`: a list

- `get_tdw_best_params()`: a list, unless `param` is set.

- `get_tdw_testing_data()`: a `data.frame`

## See also

Other Object 'Getter' Functions:
[`get_dw_pollutant()`](https://openair-project.github.io/deweather/reference/getters-dw.md)

## Author

Jack Davison

## Examples

``` r
if (FALSE) { # \dontrun{
# tune a model
tdw <- tune_dw_model(aqroadside, "no2", trees = c(1, 5))

# extract variables, for example:
get_tdw_testing_metrics(tdw)
get_tdw_best_params(tdw)
get_tdw_testing_data(tdw)
} # }
```
