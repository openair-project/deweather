# Getters for various deweather model features

`deweather` provides multiple 'getter' functions for extracting relevant
model features from a deweather model. These are a useful convenience,
particularly in conjunction with R's
[pipe](https://rdrr.io/r/base/pipeOp.html) operator (`|>`).

## Usage

``` r
get_dw_pollutant(dw)

get_dw_vars(dw)

get_dw_params(dw, param = NULL)

get_dw_input_data(dw)

get_dw_model(dw)

get_dw_engine(dw)

get_dw_importance(dw, aggregate_factors = FALSE, sort = TRUE)
```

## Arguments

- dw:

  A deweather model created with
  [`build_dw_model()`](https://openair-project.github.io/deweather/reference/build_dw_model.md).

- param:

  For `get_dw_params()`. The default (`NULL`) returns a list of model
  parameters. `param` will return one specific parameter as a character
  vector.

- aggregate_factors:

  Defaults to `FALSE`. If `TRUE`, the importance of factor inputs (e.g.,
  Weekday) will be summed into a single variable. This only applies to
  certain engines (e.g., `"xgboost"`) which report factor importance as
  disaggregate features.

- sort:

  If `TRUE`, the default, features will be sorted by their importance.
  If `FALSE`, they will be sorted alphabetically. In
  [`plot_dw_importance()`](https://openair-project.github.io/deweather/reference/plot_dw_importance.md)
  this will change the ordering of the y-axis, whereas in
  `get_dw_importance()` it will change whether `var` is returned as a
  factor or character data type.

## Value

Typically a character vector, except:

- `get_dw_params()`: a list, unless `param` is set.

- `get_dw_importance()`: a `data.frame`

- `get_dw_model()`: A
  [parsnip::model_fit](https://parsnip.tidymodels.org/reference/model_fit.html)
  object
