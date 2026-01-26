# Plot Observed vs Modelled Scatter using the 'best parameters' from [`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md)

[`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md)
determines a 'best' set of parameters automatically and models some
'final' predictions using a reserved testing dataset to evaluate the
model. This function produces a scatter (or varient)

## Usage

``` r
plot_tdw_testing_scatter(
  tdw,
  method = c("scatter", "bin", "hexbin"),
  group = NULL,
  bins = 50L,
  show_ablines = TRUE,
  show_params = TRUE,
  cols = "viridis",
  cols_ablines = c("black", "grey50")
)
```

## Arguments

- tdw:

  A deweather tuning object created with
  [`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md).

- method:

  One of `"scatter"`, `"bin"` or `"hexbin"`.

- group:

  A variable (one of the initial modelling parameters) to colour the
  scatter plot by. Only used when `method = "scatter"`. This could be
  useful to determine where the model is working most or least
  effectively, or to identify other patterns in the data.

- bins:

  The number of bins to use when `method = "bin"` or
  `method = "hexbin"`.

- show_ablines:

  Show 1:1, 2:1 and 1:2 lines to assist with model evaluation? Lines
  will appear beneath the "scatter" `method` and above either of the
  "bin" `method`s.

- show_params:

  Show an annotation of model parameters in the top-left corner of the
  scatter plot?

- cols:

  Colours to use for plotting. See
  [`openair::openColours()`](https://openair-project.github.io/openair/reference/openColours.html).

- cols_ablines:

  Colours to use for the diagonal lines, if `show_ablines = TRUE`. The
  the first colour is used for the 1:1 line, and the second for the 2:1
  and 1:2 lines. Passed to
  [`openair::openColours()`](https://openair-project.github.io/openair/reference/openColours.html).

## See also

Other Model Tuning Functions:
[`plot_tdw_tuning_metrics()`](https://openair-project.github.io/deweather/reference/plot_tdw_tuning_metrics.md),
[`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md)
