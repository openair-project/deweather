# deweather (development version)

## Major Version Changes

Version 1.0.0 of deweather is a complete re-write of the `deweather` package. This new version:

- Uses the `tidymodels` framework, allowing for more flexibility in plotting engines. `deweather` 1.0.0 launches with both `xgboost` and `lightgbm` engines available.

- Provides much more flexible partial dependency calculations, including grouped PDs.

- Uses the flexible `{mirai}` package to support parallelisation.

- Uses a consistent function and object naming scheme for easier applications.

The main reason prompting this change was the retirement of the `gbm` R package, and the slow development of `gbm3`. `xgboost` and `lightgbm` are modern, fast, popular, and highly capable implementations of gradient boosted machine learning.

The original version of deweather (including its `NEWS.md`) is archived at <https://github.com/openair-project/deweather-archive> for users still interested in the old API.

## New Features

- Model building functions:

    - `build_dw_model()` fits a deweather model, used in the rest of the package.

    - `tune_dw_model()` allows for different modelling parameters to be tweaked and experimented with.

    - `append_dw_vars()` attaches a variety of modelling variables, and is used automatically within the above two functions.

    - The `get_dw_pollutant()` family allows for specific features of deweather models to be extracted consistently.

- Visualisation functions:

    - `plot_dw_importance()` provides a quick plot of variable importance of a deweather model.
    
    - `plot_dw_partial_1d()` calculates and visualises partial dependencies of any subset of model variables.
    
    - `plot_dw_partial_2d()` calculates and visualises two-dimensional partial dependencies.
    
- Modelling functions:

    - `predict_dw()` allows for the use of a deweather model for predictions.
    
    - `simualte_dw_met()` will simulate a timeseries in which selected meteorological variables are averaged, effectively helping 'remove' the influence of met variables.
