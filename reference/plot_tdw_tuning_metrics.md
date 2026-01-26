# Plot Tuning Metrics from [`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md)

This function creates a plot of the tuning metrics from a
`TuneDeweather` object created using
[`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md).
It visualises how different hyperparameter values affect model
performance (RMSE and RSQ). This allows for the 'best' parameters to be
refined through visual inspection. This plot is likely most effective
with between 1 and 3 simultaneously tuned parameters; any more will
impede plot interpretation.

## Usage

``` r
plot_tdw_tuning_metrics(
  tdw,
  x = NULL,
  group = NULL,
  facet = NULL,
  show_std_err = TRUE,
  cols = "Set1"
)
```

## Arguments

- tdw:

  A deweather tuning object created with
  [`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md).

- x:

  The tuned parameter to plot on the x-axis. If not selected, the first
  parameter in the `metrics` dataset will be chosen.

- group, facet:

  Additional tuned parameters other than `x`, used to further control
  the plot. `group` colours the plot by another parameter, and `facet`
  splits the diagram into additional panels. Neither `group` nor `facet`
  can be the same parameter as `x`.

- show_std_err:

  Show the standard error using error bars?

- cols:

  Colours to use for plotting. See
  [`openair::openColours()`](https://openair-project.github.io/openair/reference/openColours.html).

## See also

Other Model Tuning Functions:
[`plot_tdw_testing_scatter()`](https://openair-project.github.io/deweather/reference/plot_tdw_testing_scatter.md),
[`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md)

## Author

Jack Davison
