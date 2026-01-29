#' Conveniently append common 'deweathering' variables to an air quality time
#' series
#'
#' This function conveniently manipulates a datetime ('POSIXct') column (by
#' default named 'date') into a series of columns which are useful features in
#' deweather models. Used internally by [build_dw_model()] and
#' [tune_dw_model()], but can be used directly by users if desired.
#'
#' @inheritParams shared_deweather_params
#'
#' @param data An input `data.frame` with at least one date(time) column.
#'
#' @param vars A character vector of variables of interest. Possible options
#'   include:
#'     - `"trend"`: a numeric expression of the overall time series
#'     - `"hour"`: the hour of the day (0-23)
#'     - `"weekday"`: the day of the week (Sunday through Saturday)
#'     - `"weekend"`: whether it is a weekend (Saturday, Sunday) or weekday
#'     - `"yday"`: the day of the year
#'     - `"week"`: the week of the year
#'     - `"month"`: the month of the year
#'
#' @param abbr Abbreviate weekday and month strings? Defaults to `TRUE`, which
#'   tends to look better in plots.
#'
#' @param .date The name of the 'date' column to use for manipulation.
#'
#' @seealso [openair::cutData()] for more flexible time series data conditioning.
#'
#' @export
append_dw_vars <- function(
  data,
  vars = c(
    "trend",
    "hour",
    "weekday",
    "weekend",
    "yday",
    "week",
    "month"
  ),
  abbr = TRUE,
  ...,
  .date = "date"
) {
  rlang::check_dots_empty()
  vars <- rlang::arg_match(vars, dwVars, multiple = TRUE)

  if (!.date %in% names(data)) {
    cli::cli_abort(
      c(
        "x" = "There is no column called '{(.date)}' in {.field data}.",
        "i" = "Names in {.field data}: {names(data)}"
      )
    )
  }

  if (!lubridate::is.POSIXct(data[[.date]])) {
    cli::cli_abort(
      c(
        "x" = "The column '{(.date)}' in {.field data} is not {.code POSIXct}.",
        "i" = "Class of {.field data${(.date)}}: {.code {class(data[[.date]])}}"
      )
    )
  }

  if ("trend" %in% vars) {
    data$trend <- as.numeric(data[[.date]])
  }

  if ("hour" %in% vars) {
    data$hour <- as.integer(lubridate::hour(data[[.date]]))
  }

  if ("weekday" %in% vars) {
    data$weekday <-
      lubridate::wday(data[[.date]], label = TRUE, abbr = abbr) |>
      factor(ordered = FALSE)
  }

  if ("weekend" %in% vars) {
    data$weekend <- lubridate::wday(
      data[[.date]],
      label = FALSE,
      week_start = 1L
    )
    data$weekend <- ifelse(data$weekend %in% 6:7, "weekend", "weekday")
    data$weekend <- factor(data$weekend, c("weekday", "weekend"))
  }

  if ("yday" %in% vars) {
    data$yday <- as.integer(lubridate::yday(data[[.date]]))
  }

  if ("week" %in% vars) {
    data$week <- as.integer(lubridate::week(data[[.date]]))
  }

  if ("month" %in% vars) {
    data$month <-
      lubridate::month(data[[.date]], label = TRUE, abbr = abbr) |>
      factor(ordered = FALSE)
  }

  return(data)
}

# variables which are reserved by deweather
dwVars <- c(
  "hour",
  "weekday",
  "weekend",
  "trend",
  "yday",
  "week",
  "month"
)
