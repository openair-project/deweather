#' Function to run random meteorological simulations on a gbm model
#'
#' @param dw_model Model object from running [buildMod()].
#' @param newdata Data set to which to apply the model. If missing the data used
#'   to build the model in the first place will be used.
#' @param metVars The variables that should be randomly varied. Note that these
#'   should typically be meteorological variables and not temporal emission
#'   proxies such as "hour", "weekday" or "week".
#' @param n.core Number of cores to use.
#' @param B Number of simulations
#' @export
#' @return a [tibble][tibble::tibble-package]
#' @seealso [buildMod()] to build a gbm model
#' @author David Carslaw
metSim <-
  function(
    dw_model,
    newdata,
    metVars = c("ws", "wd", "air_temp"),
    n.core = 4,
    B = 200
  ) {
    check_dwmod(dw_model)

    ## extract the model
    mod <- dw_model$model

    # pollutant name
    pollutant <- dw_model$model$response.name

    if (!"trend" %in% mod$var.names) {
      stop(
        "The model must have a trend component as one of the explanatory variables."
      )
    }

    if (missing(newdata)) {
      ## should already have variables
      newdata <- dw_model$data
    } else {
      ## add variables needed
      newdata <- prepData(newdata)
    }

    cl <- parallel::makeCluster(n.core)
    doParallel::registerDoParallel(cl)

    prediction <- foreach::foreach(
      i = 1:B,
      .inorder = FALSE,
      .combine = "rbind",
      .packages = "gbm",
      .export = "doPred"
    ) %dopar%
      doPred(newdata, mod, metVars)

    parallel::stopCluster(cl)

    # use pollutant name
    names(prediction)[2] <- pollutant

    ## Aggregate results
    prediction <- dplyr::group_by(prediction, .data$date) |>
      dplyr::summarise({{ pollutant }} := mean(.data[[pollutant]]))

    return(dplyr::tibble(prediction))
  }


## randomly sample from original data
doPred <- function(mydata, mod, metVars) {
  ## random samples
  n <- nrow(mydata)
  id <- sample(1:n, n, replace = FALSE)

  ## new data with random samples
  mydata[metVars] <- lapply(mydata[metVars], \(x) x[id])

  prediction <- gbm::predict.gbm(mod, mydata, mod$n.trees)

  prediction <- data.frame(date = mydata$date, pred = prediction)

  return(prediction)
}

doPred2 <- function(mydata, mod, metVars) {
  ## random samples
  n <- nrow(mydata)
  #id <- sample(1:n, n, replace = FALSE)
  id <- get_constrained_random_index(mydata$date)

  ## new data with random samples
  mydata[metVars] <- lapply(mydata[metVars], \(x) x[id])

  prediction <- gbm::predict.gbm(mod, mydata, mod$n.trees)

  prediction <- data.frame(date = mydata$date, pred = prediction)

  return(prediction)
}

get_constrained_random_index <- function(dates) {
  n_hours <- length((dates))

  # Extract time-of-year information
  day_of_year <- lubridate::yday(dates)
  hour_of_day <- lubridate::hour(dates)

  # Vectorized approach: for each observation, sample from valid indices
  random_indices <- integer(n_hours)

  for (i in seq_len(n_hours)) {
    # Find valid indices based on constraints
    valid_indices <- which(
      abs(day_of_year - day_of_year[i]) <= 30 &
        abs(hour_of_day - hour_of_day[i]) <= 2
    )

    # Randomly sample one valid index
    random_indices[i] <- sample(valid_indices, size = 1)
  }

  random_indices
}
