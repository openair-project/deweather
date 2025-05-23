#' Function to prepare data frame for modelling
#'
#' @description
#'
#' This function takes a data frame that contains a field `date` and other
#' variables and adds other common variables needed by the modelling functions.
#' This function is run automatically by [buildMod()] but can be used separately
#' for further analysis. These variables include:
#'
#' - **hour** - The hour of the day from 0 to 23.
#'
#' - **hour.local** - The hour in the local time zone. Note that the local time
#' zone will need to be supplied (see `local.tz`). The purpose of using
#' local time rather than UTC is that emissions can vary more strongly by local
#' time rather than UTC.
#'
#' - **weekday** - The day of the week.
#'
#' - **trend** - The trend is calculated as a decimal year.
#'
#' - **week** - The week of the year. Useful for taking account of long-term
#' seasonal variations.
#'
#' - **jday** - The Julian Day number.
#'
#' - **month** - month of the year. Useful for taking account of long-term
#' seasonal variations.
#'
#' @param mydata A data frame to process.
#' @param add Names of explanatory variables to include.
#' @param local.tz Used if hour needs to be expressed in local time. This can be
#'   useful for situations where the anthropogenic emissions source is strong
#'   and follows local time rather than UTC.
#' @param lag Variables(s) to lag. Any variables included here will add new
#'   columns to the data frame. For example `lag = "ws"` with add a new
#'   columns `lag1ws`. Adding some variables here can improve the
#'   explanatory power of the models. Variables are lagged by one unit of time.
#' @export
#' @return A data frame with new variables.
#' @author David Carslaw
prepData <- function(
  mydata,
  add = c(
    "hour",
    "hour.local",
    "weekday",
    "trend",
    "week",
    "jday",
    "month"
  ),
  local.tz = "Europe/London",
  lag = NULL
) {
  ## Some cheack to make sure data are OK.
  # does `date` exist?
  if (!"date" %in% names(mydata)) {
    cli::cli_abort("No mydata${.field date} field supplied.")
  }
  # is `date` a date?
  if (
    inherits(mydata$date, "character") |
      inherits(mydata$date, "factor") |
      inherits(mydata$date, "numeric")
  ) {
    cli::cli_abort(
      c(
        "x" = "mydata{.field $date} is of class {.code {class(mydata$date)}}",
        "i" = "Please ensure mydata{.field $data} is class {.code Date} or {.code POSIXt} (e.g., with {.fun as.POSIXct} or {.pkg lubridate})"
      )
    )
  }

  if ("hour" %in% add) {
    mydata$hour <- lubridate::hour(mydata$date)
  }

  if ("hour.local" %in% add) {
    mydata$hour.local <- lubridate::hour(lubridate::with_tz(
      mydata$date,
      local.tz
    ))
  }

  if ("weekday" %in% add) {
    mydata$weekday <- as.factor(format(mydata$date, "%A"))
  }

  if ("trend" %in% add) {
    mydata$trend <- as.numeric(mydata$date)
  }

  if ("week" %in% add) {
    mydata$week <- as.numeric(format(mydata$date, "%W"))
  }

  if ("jday" %in% add) {
    mydata$jday <- as.numeric(format(mydata$date, "%j"))
  }

  if ("month" %in% add) {
    mydata$month <- as.factor(format(mydata$date, "%b"))
  }

  ## add lagged variables
  if (!is.null(lag)) {
    for (i in seq_along(lag)) {
      mydata[[paste0("lag1", lag[i])]] <- mydata[[lag[i]]][c(
        NA,
        1:(nrow(mydata) - 1)
      )]
    }
  }

  ## NaN spells trouble for gbm for some reason
  mydata[] <- lapply(mydata, function(x) {
    replace(x, which(is.nan(x)), NA)
  })
  mydata
}
