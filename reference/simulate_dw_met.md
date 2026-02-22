# Function to run random meteorological simulations on a deweather model

This function performs random simulations to help isolate the effect of
emissions changes from meteorological variability in air quality data.
It works by repeatedly shuffling meteorological variables (like wind and
air temperature) while keeping temporal patterns intact, then predicting
pollutant concentrations using a trained deweather model.

## Usage

``` r
simulate_dw_met(
  dw,
  newdata = deweather::get_dw_input_data(dw),
  vars = c("ws", "wd", "air_temp"),
  resampling = c("constrained", "all"),
  window_day = 30,
  window_hour = 2,
  n = 200,
  aggregate = TRUE,
  ...,
  .progress = rlang::is_interactive()
)
```

## Arguments

- dw:

  A deweather model created with
  [`build_dw_model()`](https://openair-project.github.io/deweather/reference/build_dw_model.md).

- newdata:

  Data set to which to apply the model. If missing the data used to
  build the model in the first place will be used.

- vars:

  The variables that should be randomly varied. Note that these should
  typically be meteorological variables (e.g., `"ws"`, `"wd"`,
  `"air_temp"`) and not temporal emission proxies (e.g., `"hour"`,
  `"weekday"`, `"week"`).

- resampling:

  The resampling strategy. One of:

  - `"constrained"` (default), meaning that only days of the year close
    to the target date are sampled. This option is used in conjunction
    with `window_day` and `window_hour`. For example, a `window_day` of
    `30` will sample +/-30 days of the date.

  - `"all"`, meaning all dates are shuffled.

  The argument for using constrained resampling is that it resamples
  conditions for a similar time of year and / or hour of the day to
  minimise the resampling of implausible conditions e.g. very warm
  temperatures during winter.

- window_day, window_hour:

  The day of year (`window_day`) and hour of day (`window_hour`) windows
  to sample within when `resampling = "constrained"`. For example,
  `window_day = 30` samples within +/-30 days of any given date.

- n:

  The number of simulations to use.

- aggregate:

  By default, all of the simulations will be aggregated into a single
  time series. When `aggregate = FALSE`, all simulations will be
  returned in a single data frame with an `.id` column distinguishing
  between them.

- ...:

  Not currently used.

- .progress:

  Show a progress bar? Defaults to `TRUE` in interactive sessions.

## Value

a [tibble](https://tibble.tidyverse.org/reference/tibble-package.html)

## Parallel Processing

This function supports parallel processing using the `{mirai}` package.
You will likely find that the performance of this function increases if
"daemons" are set. The greatest benefits will be seen if you spawn as
many daemons as you have cores on your machine, although one fewer than
the available cores is often a good rule of thumb.

    # set workers - once per session
    mirai::daemons(4)

    # run your function as normal
    tune_dw_model(aqroadside, "no2", tree_depth = c(5, 10))

## Author

David Carslaw

Jack Davison

## Examples

``` r
if (FALSE) { # \dontrun{
dw <- build_dw_model(aqroadside, "no2")
simulate_dw_met(dw)
} # }
```
