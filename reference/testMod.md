# Function to test different meteorological normalisation models.

Function to test different meteorological normalisation models.

## Usage

``` r
testMod(
  input_data,
  vars = c("trend", "ws", "wd", "hour", "weekday", "air_temp"),
  pollutant = "nox",
  train.frac = 0.8,
  n.trees = NA,
  shrinkage = 0.1,
  interaction.depth = 5,
  bag.fraction = 0.5,
  n.minobsinnode = 10,
  cv.folds = 5,
  seed = 123,
  n.core = 4,
  plot = TRUE
)
```

## Arguments

- input_data:

  Data frame to analyse. Must contain a POSIXct field called `date`.

- vars:

  Explanatory variables to use. These variables will be used to build
  the [`gbm::gbm()`](https://rdrr.io/pkg/gbm/man/gbm.html) model. Note
  that the model must include a trend component. Several variables can
  be automatically calculated (see
  [`prepData()`](https://openair-project.github.io/deweather/reference/prepData.md)
  for details).

- pollutant:

  The name of the variable to apply meteorological normalisation to.

- train.frac:

  Fraction of data to train a model on. The model is tested against the
  withheld 0.2 proportion.

- n.trees:

  Number of trees to use. If `n.trees = NA` then the function will
  conduct cross-validation to calculate the optimum number.

- shrinkage:

  A shrinkage parameter applied to each tree in the expansion. Also
  known as the learning rate or step-size reduction; `0.001` to `0.1`
  usually work, but a smaller learning rate typically requires more
  trees. Default is `0.1`.

- interaction.depth:

  Integer specifying the maximum depth of each tree (i.e., the highest
  level of variable interactions allowed). A value of `1` implies an
  additive model, a value of `2` implies a model with up to 2-way
  interactions, etc. Default is `5`.

- bag.fraction:

  The fraction of the training set observations randomly selected to
  propose the next tree in the expansion. This introduces randomness
  into the model fit. If `bag.fraction < 1` then running the same model
  twice will result in similar but different.

- n.minobsinnode:

  Integer specifying the minimum number of observations in the terminal
  nodes of the trees. Note that this is the actual number of
  observations, not the total weight.

- cv.folds:

  Number of cross-validation folds to perform. If `cv.folds > 1` then
  [`gbm::gbm()`](https://rdrr.io/pkg/gbm/man/gbm.html), in addition to
  the usual fit, will perform a cross-validation, calculate an estimate
  of generalization error returned in `cv.error`.

- seed:

  Random number seed for reproducibility in returned model.

- n.core:

  Number of cores to use for parallel processing.

- plot:

  The default, `TRUE`, automatically prints a plot and two tables of
  statistics to review the model output. `FALSE` disables this
  behaviour.

## Value

Returns to be added.

## See also

[`buildMod()`](https://openair-project.github.io/deweather/reference/buildMod.md)
for fitting a final model

## Author

David Carslaw
