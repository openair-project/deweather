# Tune a deweather model

This function performs hyperparameter tuning for a gradient boosting
model used in deweathering air pollution data. It uses cross-validation
to find optimal hyperparameters and returns the best performing model
along with performance metrics and visualizations. Parallel processing
(e.g., through the `mirai` package) is recommended to speed up tuning -
see
<https://tune.tidymodels.org/articles/extras/optimizations.html#parallel-processing>.

## Usage

``` r
tune_dw_model(
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
  split_prop = 3/4,
  grid_levels = 5,
  v_partitions = 10,
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

- tree_depth, trees, learn_rate, mtry, min_n, loss_reduction,
  sample_size, stop_iter:

  If length 1, these parameters will be fixed. If length `2`, the
  parameter will be tuned within the range defined between the first and
  last value. For example, if `tree_depth = c(1, 5)` and
  `grid_levels = 3`, tree depths of `1`, `3`, and `5` will be tested.
  See
  [`build_dw_model()`](https://openair-project.github.io/deweather/reference/build_dw_model.md)
  for specific parameter definitions.

- engine:

  A single character string specifying what computational engine to use
  for fitting. Can be `"xgboost"`, `"lightgbm"` (boosted trees) or
  `"ranger"` (random forest). See the documentation below for more
  information.

- split_prop:

  The proportion of data to be retained for modeling/analysis. Passed to
  the `prop` argument of
  [`rsample::initial_split()`](https://rsample.tidymodels.org/reference/initial_split.html).

- grid_levels:

  An integer for the number of values of each parameter to use to make
  the regular grid. Passed to the `levels` argument of
  [`dials::grid_regular()`](https://dials.tidymodels.org/reference/grid_regular.html).

- v_partitions:

  The number of partitions of the data set to use for v-fold
  cross-validation. Passed to the `v` argument of
  [`rsample::vfold_cv()`](https://rsample.tidymodels.org/reference/vfold_cv.html).

- ...:

  Not current used.

- .date:

  The name of the 'date' column which defines the air quality
  timeseries. Passed to
  [`append_dw_vars()`](https://openair-project.github.io/deweather/reference/append_dw_vars.md)
  if needed. Also used to extract the time zone of the data for later
  restoration if `trend` is used as a variable.

## Details

The function performs the following steps:

- Removes rows with missing values in the pollutant or predictor
  variables

- Splits data into training and testing sets

- Creates a tuning grid for any parameters specified as ranges

- Performs grid search with cross-validation to find optimal
  hyperparameters

- Fits a final model using the best hyperparameters

- Generates predictions and performance metrics

At least one hyperparameter must be specified as a range (vector of
length 2) for tuning to occur. Single values are treated as fixed
parameters.

## Modelling Approaches and Parameters

### Types of Model

There are two modelling approaches available to
[`build_dw_model()`](https://openair-project.github.io/deweather/reference/build_dw_model.md):

- Boosted Trees (`xgboost`, `lightgbm`)

- Random Forest (`ranger`)

Each of these approaches take different parameters.

### Boosted Trees

Two engines are available for boosted tree models:

- `"xgboost"`

- `"lightgbm"`

The following parameters apply:

- `tree_depth`: Tree Depth

- `trees`: \# Trees

- `learn_rate`: Learning Rate

- `mtry`: \# Randomly Selected Predictors

- `min_n`: Minimal Node Size

- `loss_reduction`: Minimum Loss Reduction

- `sample_size`: Proportion Observations Sampled (`xgboost` only)

- `stop_iter`: \# Iterations Before Stopping (`xgboost` only)

### Random Forest

One engine is available for random forest models:

- `"ranger"`

The following parameters apply:

- `mtry`: \# Randomly Selected Predictors

- `trees`: \# Trees

- `min_n`: Minimal Node Size

## Author

Jack Davison
