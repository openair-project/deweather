# Function to run random meteorological simulations on a gbm model

Function to run random meteorological simulations on a gbm model

## Usage

``` r
metSim(
  dw_model,
  newdata,
  metVars = c("ws", "wd", "air_temp"),
  n.core = 4,
  B = 200
)
```

## Arguments

- dw_model:

  Model object from running
  [`buildMod()`](https://openair-project.github.io/deweather/reference/buildMod.md).

- newdata:

  Data set to which to apply the model. If missing the data used to
  build the model in the first place will be used.

- metVars:

  The variables that should be randomly varied. Note that these should
  typically be meteorological variables and not temporal emission
  proxies such as "hour", "weekday" or "week".

- n.core:

  Number of cores to use.

- B:

  Number of simulations

## Value

a [tibble](https://tibble.tidyverse.org/reference/tibble-package.html)

## See also

[`buildMod()`](https://openair-project.github.io/deweather/reference/buildMod.md)
to build a gbm model

## Author

David Carslaw
