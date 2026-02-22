#' Function to run random meteorological simulations on a deweather model
#'
#' This function performs random simulations to help isolate the effect of
#' emissions changes from meteorological variability in air quality data. It
#' works by repeatedly shuffling meteorological variables (like wind and air
#' temperature) while keeping temporal patterns intact, then predicting
#' pollutant concentrations using a trained deweather model.
#'
#' @inheritParams shared_deweather_params
#' @inheritSection shared_deweather_params Parallel Processing
#'
#' @param newdata Data set to which to apply the model. If missing the data used
#'   to build the model in the first place will be used.
#'
#' @param vars The variables that should be randomly varied. Note that these
#'   should typically be meteorological variables (e.g., `"ws"`, `"wd"`,
#'   `"air_temp"`) and not temporal emission proxies (e.g., `"hour"`,
#'   `"weekday"`, `"week"`).
#'
#' @param resampling The resampling strategy. One of:
#'
#'  - `"constrained"` (default), meaning that only days of the year close to
#'   the target date are sampled. This option is used in conjunction with
#'   `window_day` and `window_hour`. For example, a `window_day` of `30` will
#'   sample +/-30 days of the date.
#'
#'   - `"all"`, meaning all dates are shuffled.
#'
#'   The argument for using constrained resampling is that it resamples
#'   conditions for a similar time of year and / or hour of the day to minimise
#'   the resampling of implausible conditions e.g. very warm temperatures during
#'   winter.
#'
#' @param window_day,window_hour The day of year (`window_day`) and hour of day
#'   (`window_hour`) windows to sample within when `resampling = "constrained"`.
#'   For example, `window_day = 30` samples within +/-30 days of any given date.
#'
#' @param n The number of simulations to use.
#'
#' @param aggregate By default, all of the simulations will be aggregated into a
#'   single time series. When `aggregate = FALSE`, all simulations will be
#'   returned in a single data frame with an `.id` column distinguishing between
#'   them.
#'
#' @export
#'
#' @return a [tibble][tibble::tibble-package]
#'
#' @examples
#' \dontrun{
#' dw <- build_dw_model(aqroadside, "no2")
#' simulate_dw_met(dw)
#' }
#'
#' @author David Carslaw
#' @author Jack Davison
simulate_dw_met <-
  function(
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
  ) {
    check_deweather(dw)
    resampling <- rlang::arg_match(resampling, c("constrained", "all"))

    # extract model components
    model <- get_dw_model(dw)
    model_vars <- get_dw_vars(dw)
    pollutant <- get_dw_pollutant(dw)
    tz <- dw$tz

    if (!"trend" %in% model_vars) {
      cli::cli_abort(
        "{.arg dw} must have a trend component as one of the explanatory variables."
      )
    }

    # if daemons are set, need to load packages in the workers, otherwise don't
    if (mirai::daemons_set()) {
      prediction <-
        purrr::map(
          .x = 1:n,
          .f = purrr::in_parallel(
            \(x) {
              library(deweather)
              contr_one_hot <- parsnip::contr_one_hot
              sample_and_predict(
                mydata = newdata,
                mod = model,
                vars = vars,
                resampling = resampling,
                window_day = window_day,
                window_hour = window_hour,
                sample_fun = get_constrained_indices_cpp,
                tz = tz
              )
            },
            sample_and_predict = sample_and_predict,
            newdata = newdata,
            model = model,
            vars = vars,
            resampling = resampling,
            window_day = window_day,
            window_hour = window_hour,
            tz = tz,
            get_constrained_indices_cpp = get_constrained_indices_cpp
          ),
          .progress = .progress
        ) |>
        purrr::list_rbind()
    } else {
      prediction <-
        purrr::map(
          .x = 1:n,
          .f = purrr::in_parallel(
            \(x) {
              sample_and_predict(
                mydata = newdata,
                mod = model,
                vars = vars,
                resampling = resampling,
                window_day = window_day,
                window_hour = window_hour,
                sample_fun = get_constrained_indices_cpp,
                tz = tz
              )
            },
            sample_and_predict = sample_and_predict,
            newdata = newdata,
            model = model,
            vars = vars,
            resampling = resampling,
            window_day = window_day,
            window_hour = window_hour,
            tz = tz,
            get_constrained_indices_cpp = get_constrained_indices_cpp
          ),
          .progress = .progress
        ) |>
        purrr::list_rbind()
    }

    # use pollutant name
    names(prediction)[2] <- pollutant

    # Aggregate results
    if (aggregate) {
      prediction <-
        dplyr::summarise(
          prediction,
          {{ pollutant }} := mean(.data[[pollutant]]),
          .by = "date"
        ) |>
        dplyr::tibble()
    } else {
      prediction <-
        dplyr::mutate(
          prediction,
          .id = dplyr::row_number(),
          .by = "date",
          .before = 0
        ) |>
        dplyr::tibble()
    }

    return(prediction)
  }

# get random samples and predict
sample_and_predict <- function(
  mydata,
  mod,
  vars,
  resampling,
  window_day,
  window_hour,
  sample_fun,
  tz
) {
  n <- nrow(mydata)

  if (resampling == "all") {
    id <- sample(1:n, n, replace = FALSE)
  }

  if (resampling == "constrained") {
    # Extract features
    dates <- as.POSIXct(mydata$trend, tz = tz)
    doy <- lubridate::yday(dates)
    hod <- lubridate::hour(dates)

    # Call C++ with the window arguments
    id <- sample_fun(
      doy = doy,
      hod = hod,
      day_win = window_day,
      hour_win = window_hour
    )
  }

  # new data with random samples
  mydata[vars] <- lapply(mydata[vars], \(x) x[id])

  # predict
  prediction <- parsnip::predict.model_fit(mod, new_data = mydata)

  # return data
  prediction <- dplyr::tibble(
    date = as.POSIXct(mydata$trend, tz = tz),
    pred = prediction$.pred
  )

  return(prediction)
}
