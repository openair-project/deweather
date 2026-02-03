# Package index

## Data

Example datasets included with the package, used to demonstrate and test
deweathering functions.

- [`aqroadside`](https://openair-project.github.io/deweather/reference/aqroadside.md)
  : Example air quality monitoring data for openair

## Tune

Tune hyperparameters for a deweathering model before it is fit. A ‘best’
parameter set is automatically determined, but other functions are
provided to allow for closer interrogation so that these can be refined.

- [`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md)
  : Tune a deweather model

- [`plot_tdw_tuning_metrics()`](https://openair-project.github.io/deweather/reference/plot_tdw_tuning_metrics.md)
  :

  Plot Tuning Metrics from
  [`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md)

- [`plot_tdw_testing_scatter()`](https://openair-project.github.io/deweather/reference/plot_tdw_testing_scatter.md)
  :

  Plot Observed vs Modelled Scatter using the 'best parameters' from
  [`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md)

## Build

Core functions for fitting deweathering models, used throughout the rest
of the `deweather` package for interpretation and prediction.

- [`build_dw_model()`](https://openair-project.github.io/deweather/reference/build_dw_model.md)
  : Build a Deweather Model

- [`finalise_tdw_model()`](https://openair-project.github.io/deweather/reference/finalise_tdw_model.md)
  :

  Use the 'best parameters' determined by
  [`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md)
  to build a Deweather Model

- [`append_dw_vars()`](https://openair-project.github.io/deweather/reference/append_dw_vars.md)
  : Conveniently append common 'deweathering' variables to an air
  quality time series

## Examine

‘getters’ to extract specific features of a built `deweather` model or a
`deweather` ‘tuning’ object.

- [`get_dw_pollutant()`](https://openair-project.github.io/deweather/reference/getters-dw.md)
  [`get_dw_vars()`](https://openair-project.github.io/deweather/reference/getters-dw.md)
  [`get_dw_engine()`](https://openair-project.github.io/deweather/reference/getters-dw.md)
  [`get_dw_params()`](https://openair-project.github.io/deweather/reference/getters-dw.md)
  [`get_dw_input_data()`](https://openair-project.github.io/deweather/reference/getters-dw.md)
  [`get_dw_model()`](https://openair-project.github.io/deweather/reference/getters-dw.md)
  [`get_dw_importance()`](https://openair-project.github.io/deweather/reference/getters-dw.md)
  : Getters for various deweather model features
- [`get_tdw_pollutant()`](https://openair-project.github.io/deweather/reference/getters-tdw.md)
  [`get_tdw_vars()`](https://openair-project.github.io/deweather/reference/getters-tdw.md)
  [`get_tdw_engine()`](https://openair-project.github.io/deweather/reference/getters-tdw.md)
  [`get_tdw_best_params()`](https://openair-project.github.io/deweather/reference/getters-tdw.md)
  [`get_tdw_tuning_metrics()`](https://openair-project.github.io/deweather/reference/getters-tdw.md)
  [`get_tdw_testing_metrics()`](https://openair-project.github.io/deweather/reference/getters-tdw.md)
  [`get_tdw_testing_data()`](https://openair-project.github.io/deweather/reference/getters-tdw.md)
  : Getters for various deweather tuning object features

## Visualise

Functions for visualizing model components and relationships, including
variable importance and partial dependence plots.

- [`plot_dw_importance()`](https://openair-project.github.io/deweather/reference/plot_dw_importance.md)
  : Visualise deweather model feature importance
- [`plot_dw_partial_1d()`](https://openair-project.github.io/deweather/reference/plot_dw_partial_1d.md)
  : Create partial dependence plots for deweather models
- [`plot_dw_partial_2d()`](https://openair-project.github.io/deweather/reference/plot_dw_partial_2d.md)
  : Create a 2-way partial dependence plot for deweather models

## Predict

Functions to apply a deweathering model for prediction.

- [`predict_dw()`](https://openair-project.github.io/deweather/reference/predict_dw.md)
  : Use a deweather model to predict with a new dataset
- [`simulate_dw_met()`](https://openair-project.github.io/deweather/reference/simulate_dw_met.md)
  : Function to run random meteorological simulations on a deweather
  model
- [`plot_sim_trend()`](https://openair-project.github.io/deweather/reference/plot_sim_trend.md)
  : Plot a simulated 'deweathered' trend, optionally with its input data
