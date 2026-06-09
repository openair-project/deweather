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

    # Pre-compute all n sets of shuffled row indices at once.
    #
    # For constrained resampling the C++ function builds the (doy, hour) grid
    # and candidate lists ONCE, then draws n independent samples per
    # observation — total cost ≈ one single-simulation call regardless of n.
    # Previously, get_constrained_indices_cpp was called inside each task,
    # rebuilding the full grid every time: 50 calls × ~0.8 s = 40 s overhead
    # for a 144 k-row dataset.
    dates <- as.POSIXct(newdata$trend, tz = tz)

    if (resampling == "constrained") {
      doy <- lubridate::yday(dates)
      hod <- lubridate::hour(dates)
      id_mat <- get_constrained_indices_multi_cpp(doy, hod, window_day, window_hour, n)
    } else {
      n_rows <- nrow(newdata)
      id_mat <- replicate(n, sample.int(n_rows, n_rows, replace = FALSE))
    }

    # Convert to a list so each task carries only its own ~576 KB index vector,
    # not the full matrix.
    id_list <- lapply(seq_len(n), function(j) id_mat[, j])

    if (mirai::daemons_set()) {
      prediction <-
        purrr::map2(
          seq_len(n),
          id_list,
          purrr::in_parallel(
            \(i, id) {
              library(deweather)
              contr_one_hot <- parsnip::contr_one_hot
              nd <- newdata
              nd[vars] <- lapply(nd[vars], \(x) x[id])
              pred <- parsnip::predict.model_fit(model, new_data = nd)
              dplyr::tibble(
                date = as.POSIXct(nd$trend, tz = tz),
                pred = pred$.pred
              )
            },
            newdata = newdata,
            model = model,
            vars = vars,
            tz = tz
          ),
          .progress = .progress
        ) |>
        purrr::list_rbind()
    } else {
      prediction <-
        purrr::map2(
          seq_len(n),
          id_list,
          \(i, id) {
            nd <- newdata
            nd[vars] <- lapply(nd[vars], \(x) x[id])
            pred <- parsnip::predict.model_fit(model, new_data = nd)
            dplyr::tibble(
              date = as.POSIXct(nd$trend, tz = tz),
              pred = pred$.pred
            )
          },
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
