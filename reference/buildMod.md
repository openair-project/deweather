# Function to apply meteorological normalisation

This is the main function to apply a
[`gbm::gbm()`](https://rdrr.io/pkg/gbm/man/gbm.html) model to a data
set.

## Usage

``` r
buildMod(
  input_data,
  vars = c("trend", "ws", "wd", "hour", "weekday", "air_temp"),
  pollutant = "nox",
  sam.size = nrow(input_data),
  n.trees = 200,
  shrinkage = 0.1,
  interaction.depth = 5,
  bag.fraction = 0.5,
  n.minobsinnode = 10,
  cv.folds = 0,
  simulate = FALSE,
  B = 100,
  n.core = 4,
  seed = 123,
  type = "PSOCK"
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

- sam.size:

  The number of random samples to extract from the data for model
  building. While it is possible to use the full data set, for data sets
  spanning years the model building can take a very long time to run.
  Additionally, there will be diminishing returns in terms of model
  accuracy. If `sam.size` is greater than the number of number of rows
  of data, the number of rows of data is used instead.

- n.trees:

  Number of trees to fit.

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

- simulate:

  Should the original time series be randomly sampled with replacement?
  The default is `FALSE`. Setting `simulate = TRUE` can be useful for
  estimating model uncertainties. In which case models should be run
  multiple times with `B = 1` and a different value of `seed` e.g.
  `seed = runif(1)`.

- B:

  Number of bootstrap simulations for partial dependence plots.

- n.core:

  Number of cores to use for parallel processing.

- seed:

  Random number seed for reproducibility in returned model.

- type:

  One of the supported parallelisation types. See
  [`parallel::makeCluster()`](https://rdrr.io/r/parallel/makeCluster.html).

## Value

Returns a list including the model, influence data frame and partial
dependence data frame.

## See also

[`testMod()`](https://openair-project.github.io/deweather/reference/testMod.md)
for testing models before they are built.

[`metSim()`](https://openair-project.github.io/deweather/reference/metSim.md)
for using a built model with meteorological simulations.

[`plot2Way()`](https://openair-project.github.io/deweather/reference/plot2Way.md),
[`plotInfluence()`](https://openair-project.github.io/deweather/reference/plotInfluence.md)
and
[`plotPD()`](https://openair-project.github.io/deweather/reference/plotPD.md)
for visualising built models.

## Author

David Carslaw
