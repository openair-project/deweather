# Changelog

## deweather 1.0.0

### Major Version Changes

Version 1.0.0 of deweather is a complete re-write of the `deweather`
package. This new version:

- Uses the `tidymodels` framework, allowing for more flexibility in
  plotting engines. `deweather` 1.0.0 launches with both `xgboost` and
  `lightgbm` engines available.

- Provides much more flexible partial dependency calculations, including
  grouped PDs.

- Uses the flexible [mirai](https://mirai.r-lib.org) package to support
  parallelisation.

- Uses a consistent function and object naming scheme for easier
  applications.

The main reason prompting this change was the retirement of the `gbm` R
package, and the slow development of `gbm3`. `xgboost` and `lightgbm`
are modern, fast, popular, and highly capable implementations of
gradient boosted machine learning.

The original version of deweather (including its `NEWS.md`) is archived
at <https://github.com/openair-project/deweather-archive> for users
still interested in the old API.

### New Features

- Model building functions:

  - [`build_dw_model()`](https://openair-project.github.io/deweather/reference/build_dw_model.md)
    fits a deweather model, used in the rest of the package.

  - [`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md)
    allows for different modelling parameters to be tweaked and
    experimented with.

  - [`append_dw_vars()`](https://openair-project.github.io/deweather/reference/append_dw_vars.md)
    attaches a variety of modelling variables, and is used automatically
    within the above two functions.

  - The
    [`get_dw_pollutant()`](https://openair-project.github.io/deweather/reference/getters-dw.md)
    family allows for specific features of deweather models to be
    extracted consistently.

- Visualisation functions:

  - [`plot_dw_importance()`](https://openair-project.github.io/deweather/reference/plot_dw_importance.md)
    provides a quick plot of variable importance of a deweather model.

  - [`plot_dw_partial_1d()`](https://openair-project.github.io/deweather/reference/plot_dw_partial_1d.md)
    calculates and visualises partial dependencies of any subset of
    model variables.

  - [`plot_dw_partial_2d()`](https://openair-project.github.io/deweather/reference/plot_dw_partial_2d.md)
    calculates and visualises two-dimensional partial dependencies.

- Modelling functions:

  - [`predict_dw()`](https://openair-project.github.io/deweather/reference/predict_dw.md)
    allows for the use of a deweather model for predictions.

  - `simualte_dw_met()` will simulate a timeseries in which selected
    meteorological variables are averaged, effectively helping ‘remove’
    the influence of met variables.
