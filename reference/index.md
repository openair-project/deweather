# Package index

## Data

In-built data to demonstrate deweather functions.

- [`road_data`](https://openair-project.github.io/deweather/reference/road_data.md)
  : Example data for deweather

## Build

Functions to test and build
[deweather](https://openair-project.github.io/deweather/) models

- [`testMod()`](https://openair-project.github.io/deweather/reference/testMod.md)
  : Function to test different meteorological normalisation models.
- [`buildMod()`](https://openair-project.github.io/deweather/reference/buildMod.md)
  : Function to apply meteorological normalisation

## Examine

Functions to visualise or otherwise examine
[`buildMod()`](https://openair-project.github.io/deweather/reference/buildMod.md)
outputs

- [`plot2Way()`](https://openair-project.github.io/deweather/reference/plot2Way.md)
  : Plot two-way interactions from gbm model
- [`plotInfluence()`](https://openair-project.github.io/deweather/reference/plotInfluence.md)
  : Plot a GBM influence plot
- [`plotPD()`](https://openair-project.github.io/deweather/reference/plotPD.md)
  : Function to plot partial dependence plots with bootstrap
  uncertainties
- [`gbmInteractions()`](https://openair-project.github.io/deweather/reference/gbmInteractions.md)
  : Quantify most important 2-way interactions

## Predict

Functions to use
[deweather](https://openair-project.github.io/deweather/) models to
predict air pollution concentrations

- [`metSim()`](https://openair-project.github.io/deweather/reference/metSim.md)
  : Function to run random meteorological simulations on a gbm model

## Utility

Other assorted functions to support
[deweather](https://openair-project.github.io/deweather/)

- [`prepData()`](https://openair-project.github.io/deweather/reference/prepData.md)
  : Function to prepare data frame for modelling
- [`diurnalGbm()`](https://openair-project.github.io/deweather/reference/diurnalGbm.md)
  : Plot diurnal changes, removing the effect of meteorology
