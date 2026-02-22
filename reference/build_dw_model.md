# Build a Deweather Model

This function builds a 'deweathering' machine learning model with useful
methods for interrogating it in an air quality and meteorological
context. It uses any number of variables (most usefully meteorological
variables like wind speed and wind direction and temporal variables
defined in
[`append_dw_vars()`](https://openair-project.github.io/deweather/reference/append_dw_vars.md))
to fit a model predicting a given `pollutant`. While these models are
useful for 'removing' the effects of meteorology from an air quality
time series (e.g., through
[`simulate_dw_met()`](https://openair-project.github.io/deweather/reference/simulate_dw_met.md)),
they are also useful for explanatory analysis (e.g., through
[`plot_dw_partial_1d()`](https://openair-project.github.io/deweather/reference/plot_dw_partial_1d.md)).

## Usage

``` r
build_dw_model(
  data,
  pollutant,
  vars = c("trend", "ws", "wd", "hour", "weekday", "air_temp"),
  tree_depth = 5,
  trees = 50L,
  learn_rate = 0.1,
  mtry = NULL,
  min_n = 10L,
  loss_reduction = 0,
  sample_size = 1L,
  stop_iter = 45L,
  engine = c("xgboost", "lightgbm", "ranger"),
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

  Tree Depth `<xgboost|lightgbm>`

  An integer for the maximum depth of the tree (i.e., number of splits).

- trees:

  Number of Trees `<xgboost|lightgbm|ranger>`

  An integer for the number of trees contained in the ensemble.

- learn_rate:

  Learning Rate `<xgboost|lightgbm>`

  A number for the rate at which the boosting algorithm adapts from
  iteration-to-iteration. This is sometimes referred to as the shrinkage
  parameter.

- mtry:

  Number of Randomly Selected Predictors `<xgboost|lightgbm|ranger>`

  A number for the number (or proportion) of predictors that will be
  randomly sampled at each split when creating the tree models.

- min_n:

  Minimal Node Size `<xgboost|lightgbm|ranger>`

  An integer for the minimum number of data points in a node that is
  required for the node to be split further.

- loss_reduction:

  Minimum Loss Reduction `<xgboost|lightgbm>`

  A number for the reduction in the loss function required to split
  further.

- sample_size:

  Proportion Observations Sampled `<xgboost>`

  A number for the number (or proportion) of data that is exposed to the
  fitting routine.

- stop_iter:

  Number of Iterations Before Stopping `<xgboost>`

  The number of iterations without improvement before stopping.

- engine:

  A single character string specifying what computational engine to use
  for fitting. Can be `"xgboost"`, `"lightgbm"` (boosted trees) or
  `"ranger"` (random forest). See the documentation below for more
  information.

- ...:

  Used to pass additional engine-specific parameters to the model. The
  parameters listed here can be tuned using
  [`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md).
  All other parameters must be fixed.

  - `alpha`: `<xgboost>` L1 regularization term on weights.

  - `lambda`: `<xgboost>` L2 regularization term on weights.

  - `num_leaves`: `<lightgbm>` max number of leaves in one tree.

  - `regularization.factor`: `<ranger>` Regularization factor (gain
    penalization).

  - `regularization.usedepth`: `<ranger>` Consider the depth in
    regularization? (`TRUE`/`FALSE`).

  - `splitrule`: `<ranger>` Splitting rule. One of
    dials::ranger_reg_rules.

  - `alpha`: `<ranger>` Significance threshold to allow splitting (for
    `splitrule = "maxstat"`).

  - `minprop`: `<ranger>` Lower quantile of covariate distribution to be
    considered for splitting (for `splitrule = "maxstat"`).

  - `num.random.splits`: `<ranger>` Number of random splits to consider
    for each candidate splitting variable (for
    `splitrule = "extratrees"`).

- .date:

  The name of the 'date' column which defines the air quality
  timeseries. Passed to
  [`append_dw_vars()`](https://openair-project.github.io/deweather/reference/append_dw_vars.md)
  if needed. Also used to extract the time zone of the data for later
  restoration if `trend` is used as a variable.

## Value

a 'Deweather' object for further analysis

## Modelling Approaches and Parameters

### Types of Model

There are two modelling approaches available to `build_dw_model()`:

- Boosted Trees (`xgboost`, `lightgbm`)

- Random Forest (`ranger`)

Each of these approaches take different parameters.

### Boosted Trees

Two engines are available for boosted tree models:

- `"xgboost"`

- `"lightgbm"`

The following universal parameters apply and are tunable:

- `tree_depth`: Tree Depth

- `trees`: \# Trees

- `learn_rate`: Learning Rate

- `mtry`: \# Randomly Selected Predictors

- `min_n`: Minimal Node Size

- `loss_reduction`: Minimum Loss Reduction

- `sample_size`: Proportion Observations Sampled (`xgboost` only)

- `stop_iter`: \# Iterations Before Stopping (`xgboost` only)

The following `xgboost`-specific parameters are tunable:

- `alpha`: L1 regularization term on weights. Increasing this value will
  make model more conservative

- `lambda`: L2 regularization term on weights. Increasing this value
  will make model more conservative

The following `lightgbm`-specific parameters are tunable:

- `num_leaves`: max number of leaves in one tree

### Random Forest

One engine is available for random forest models:

- `"ranger"`

The following universal parameters apply and are tunable:

- `mtry`: \# Randomly Selected Predictors

- `trees`: \# Trees

- `min_n`: Minimal Node Size

The following `ranger`-specific parameters are tunable:

- `regularization.factor`: Regularization factor (gain penalization)

- `regularization.usedepth`: Consider the depth in regularization?
  (`TRUE`/`FALSE`)

- `splitrule`: Splitting rule. One of dials::ranger_reg_rules

- `alpha`: Significance threshold to allow splitting (for
  `splitrule = "maxstat"`)

- `minprop`: Lower quantile of covariate distribution to be considered
  for splitting (for `splitrule = "maxstat"`)

- `num.random.splits`: Number of random splits to consider for each
  candidate splitting variable (for `splitrule = "extratrees"`)

## See also

[`finalise_tdw_model()`](https://openair-project.github.io/deweather/reference/finalise_tdw_model.md)

## Author

Jack Davison

## Examples

``` r
if (FALSE) { # \dontrun{
dw <- build_dw_model(aqroadside, "no2")
} # }
```
