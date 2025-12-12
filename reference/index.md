# Package index

## Data

Example datasets included with the package, used to demonstrate and test
deweathering functions.

- [`aqroadside`](https://openair-project.github.io/deweather/reference/aqroadside.md)
  : Example air quality monitoring data for openair

## Build

Core functions for tuning and fitting deweathering models, including
parameter tuning, model construction and adding derived variables.

- [`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md)
  : Tune a deweather model
- [`build_dw_model()`](https://openair-project.github.io/deweather/reference/build_dw_model.md)
  : Build a Deweather Model
- [`append_dw_vars()`](https://openair-project.github.io/deweather/reference/append_dw_vars.md)
  : Conveniently append common 'deweathering' variables to an air
  quality time series

## Examine

Methods to examine a deweathering model; currently ‘getters’ to extract
specific features of a built model.

- [`get_dw_pollutant()`](https://openair-project.github.io/deweather/reference/getters-dw.md)
  [`get_dw_vars()`](https://openair-project.github.io/deweather/reference/getters-dw.md)
  [`get_dw_params()`](https://openair-project.github.io/deweather/reference/getters-dw.md)
  [`get_dw_input_data()`](https://openair-project.github.io/deweather/reference/getters-dw.md)
  [`get_dw_model()`](https://openair-project.github.io/deweather/reference/getters-dw.md)
  [`get_dw_engine()`](https://openair-project.github.io/deweather/reference/getters-dw.md)
  [`get_dw_importance()`](https://openair-project.github.io/deweather/reference/getters-dw.md)
  : Getters for various deweather model features

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
