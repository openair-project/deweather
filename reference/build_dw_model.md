# Build a Deweather Model

This function builds a boosted decision tree machine learning model with
useful methods for interrogating it in an air quality and meteorological
context. Currently, only the
[xgboost](https://rdrr.io/pkg/xgboost/man/xgboost.html) engine is
supported.

## Usage

``` r
build_dw_model(
  data,
  pollutant,
  vars = c("trend", "ws", "wd", "hour", "weekday", "air_temp"),
  tree_depth = 5,
  trees = 200L,
  learn_rate = 0.1,
  mtry = NULL,
  min_n = 10L,
  loss_reduction = 0,
  sample_size = 1L,
  stop_iter = 190L,
  engine = c("xgboost", "lightgbm"),
  ...,
  .date = "date"
)
```

## Arguments

- data:

  An input `data.frame` containing one pollutant column (defined using
  `pollutant`) and a collection of feature columns (defined using
  `vars`).

- pollutant:

  The name of the column (likely a pollutant) in `data` to predict.

- vars:

  The name of the columns in `data` to use as model features - i.e., to
  predict the values in the `pollutant` column. Any character columns
  will be coerced to factors. `"hour"`, `"weekday"`, `"trend"`,
  `"yday"`, `"week"`, and `"month"` are special terms and will be passed
  to
  [`append_dw_vars()`](https://openair-project.github.io/deweather/reference/append_dw_vars.md)
  if not present in `names(data)`.

- tree_depth:

  An integer for the maximum depth of the tree (i.e. number of splits)
  (specific engines only).

- trees:

  An integer for the number of trees contained in the ensemble.

- learn_rate:

  A number for the rate at which the boosting algorithm adapts from
  iteration-to-iteration (specific engines only). This is sometimes
  referred to as the shrinkage parameter.

- mtry:

  A number for the number (or proportion) of predictors that will be
  randomly sampled at each split when creating the tree models (specific
  engines only).

- min_n:

  An integer for the minimum number of data points in a node that is
  required for the node to be split further.

- loss_reduction:

  A number for the reduction in the loss function required to split
  further (specific engines only).

- sample_size:

  A number for the number (or proportion) of data that is exposed to the
  fitting routine. For `xgboost`, the sampling is done at each iteration
  while `C5.0` samples once during training.

- stop_iter:

  The number of iterations without improvement before stopping (specific
  engines only).

- engine:

  A single character string specifying what computational engine to use
  for fitting.

- ...:

  Not current used.

- .date:

  The name of the 'date' column which defines the air quality
  timeseries. Passed to
  [`append_dw_vars()`](https://openair-project.github.io/deweather/reference/append_dw_vars.md)
  if needed. Also used to extract the time zone of the data for later
  restoration if `trend` is used as a variable.

## Value

a 'Deweather' object for further analysis
