#' y range taking account of expanded uncertainties
#' @noRd
rng <- function(x) {
  ## if no CI information, just return
  if (all(is.na(x[, c("lower", "upper")]))) {
    lims <- NULL
    return(lims)
  }

  lims <- range(c(x$lower, x$upper), na.rm = TRUE)
  inc <- 0.04 * abs(lims[2] - lims[1])
  lims <- c(lims[1] - inc, lims[2] + inc)

  lims
}


#' @noRd
prettyGap <- function(x, n = 100) {
  return(diff(pretty(x, n))[1])
}

#' @noRd
round_any <- function(x, accuracy, f = round) {
  f(x / accuracy) * accuracy
}

#' function to check if an object is a dw model
#' @noRd
check_dwmod <- function(dw_model) {
  if (missing(dw_model)) {
    cli::cli_abort(
      c(
        "x" = "No {.field dw_model} has been provided.",
        "i" = "Please supply a {.pkg deweather} model from {.fun buildMod}."
      ),
      call = NULL
    )
  }

  if (!inherits(dw_model, "deweather")) {
    cli::cli_abort(
      c(
        "x" = "Provided {.field dw_model} is of class {.class {class(dw_model)}}.",
        "i" = "Please supply a {.pkg deweather} model from {.fun buildMod}."
      ),
      call = NULL
    )
  }
}

#' Copied from openair
#' @noRd
decimalDate <- function(x, date = "date") {
  thedata <- x
  x <- x[, date]
  x.year <- floor(x)
  ## fraction of the year
  x.frac <- x - x.year
  ## number of seconds in each year
  x.sec.yr <- unclass(ISOdate(x.year + 1, 1, 1, 0, 0, 0)) -
    unclass(ISOdate(x.year, 1, 1, 0, 0, 0))
  ## now get the actual time
  x.actual <- ISOdate(x.year, 1, 1, 0, 0, 0) + x.frac * x.sec.yr
  x.actual <- as.POSIXct(trunc(x.actual, "hours"), "GMT")
  thedata$date <- x.actual
  thedata
}
