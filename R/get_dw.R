#' Getters for various deweather model features
#'
#' @description
#'
#' `deweather` provides multiple 'getter' functions for extracting relevant
#' model features from a deweather model and/or tuning objects. These are a
#' useful convenience, particularly in conjunction with R's [pipe][pipeOp]
#' operator (`|>`).
#'
#' @param dw A `deweather` model created with [build_dw_model()].
#'
#' @param param For [get_dw_params()] and [get_tdw_best_params()]. The default
#'   (`NULL`) returns a list of model parameters. `param` will return one
#'   specific parameter as a character vector.
#'
#' @param aggregate_factors Defaults to `FALSE`. If `TRUE`, the importance of
#'   factor inputs (e.g., Weekday) will be summed into a single variable. This
#'   only applies to certain engines (e.g., `"xgboost"`) which report factor
#'   importance as disaggregate features.
#'
#' @param sort If `TRUE`, the default, features will be sorted by their
#'   importance. If `FALSE`, they will be sorted alphabetically. In
#'   [plot_dw_importance()] this will change the ordering of the y-axis, whereas
#'   in [get_dw_importance()] it will change whether `var` is returned as a
#'   factor or character data type.
#'
#' @return Typically a character vector, except:
#' - [get_dw_params()]: a list, unless `param` is set.
#' - [get_dw_importance()]: a `data.frame`
#' - [get_dw_model()]: A [parsnip::model_fit] object
#'
#' @family Object 'Getter' Functions
#'
#' @rdname getters-dw
#' @order 1
#' @export
get_dw_pollutant <- function(dw) {
  check_deweather(dw)
  dw$pollutant
}

#' @rdname getters-dw
#' @order 2
#' @export
get_dw_vars <- function(dw) {
  check_deweather(dw)
  dw$vars$names
}

#' @rdname getters-dw
#' @order 3
#' @export
get_dw_engine <- function(dw) {
  check_deweather(dw)
  dw$engine$engine
}

#' @rdname getters-dw
#' @order 4
#' @export
get_dw_params <- function(dw, param = NULL) {
  check_deweather(dw)
  params <- dw$params
  if (is.null(param)) {
    return(params)
  } else {
    param <- rlang::arg_match(param, names(params))
    params[[param]]
  }
}

#' @rdname getters-dw
#' @order 5
#' @export
get_dw_input_data <- function(dw) {
  check_deweather(dw)
  dw$data$input
}

#' @rdname getters-dw
#' @order 6
#' @export
get_dw_model <- function(dw) {
  check_deweather(dw)
  dw$model
}

#' @rdname getters-dw
#' @order 7
#' @export
get_dw_importance <-
  function(dw, aggregate_factors = FALSE, sort = TRUE) {
    check_deweather(dw)
    if (aggregate_factors) {
      importance <- aggregate_importance_factors(dw)
    } else {
      importance <- dw$data$importance
    }

    if (!sort) {
      importance$var <- as.character(importance$var)
    }

    return(importance)
  }

#' Getters for various deweather tuning object features
#'
#' @description
#'
#' `deweather` provides multiple 'getter' functions for extracting relevant
#' model features from a deweather model and/or tuning objects. These are a
#' useful convenience, particularly in conjunction with R's [pipe][pipeOp]
#' operator (`|>`).
#'
#' @inheritParams get_dw_params
#'
#' @param tdw A `deweather` tuning object created with [tune_dw_model()].
#'
#' @param metric For [get_tdw_tuning_metrics()] and [get_tdw_testing_metrics()].
#'   The default (`NULL`) returns a complete set of model parameters. `metric`
#'   will return one specific parameter. `metric` must be one of the
#'   [openair::aqStats()] metrics for [get_tdw_tuning_metrics()] and one of
#'   `"rmse"` or `"rsq"` for [get_tdw_testing_metrics()].
#'
#' @return Typically a character vector, except:
#' - [get_tdw_testing_metrics()]: a list
#' - [get_tdw_best_params()]: a list, unless `param` is set.
#' - [get_tdw_testing_data()]: a `data.frame`
#'
#' @family Object 'Getter' Functions
#'
#' @rdname getters-tdw
#' @order 1
#' @export
get_tdw_pollutant <- function(tdw) {
  check_deweather(tdw, "tuneDeweather")
  tdw$pollutant
}

#' @rdname getters-tdw
#' @order 2
#' @export
get_tdw_vars <- function(tdw) {
  check_deweather(tdw, "tuneDeweather")
  tdw$vars$names
}

#' @rdname getters-tdw
#' @order 3
#' @export
get_tdw_engine <- function(tdw) {
  check_deweather(tdw, "tuneDeweather")
  tdw$engine$engine
}

#' @rdname getters-tdw
#' @order 4
#' @export
get_tdw_best_params <- function(tdw, param = NULL) {
  check_deweather(tdw, "tuneDeweather")
  params <- tdw$best_params
  if (is.null(param)) {
    return(params)
  } else {
    param <- rlang::arg_match(param, names(params))
    params[[param]]
  }
}

#' @rdname getters-tdw
#' @order 5
#' @export
get_tdw_tuning_metrics <- function(tdw, metric = NULL) {
  check_deweather(tdw, "tuneDeweather")
  x <- tdw$metrics
  if (!is.null(metric)) {
    opts <- unique(x$metric)
    rlang::arg_match(metric, opts)
    x <- x[x$metric == metric, ]
  }
  x
}

#' @rdname getters-tdw
#' @order 6
#' @export
get_tdw_testing_metrics <- function(tdw, metric = NULL) {
  check_deweather(tdw, "tuneDeweather")
  x <- as.list(tdw$final_fit$metrics)
  if (!is.null(metric)) {
    rlang::arg_match(metric, names(x))
    x <- x[[metric]]
  }
  x
}

#' @rdname getters-tdw
#' @order 7
#' @export
get_tdw_testing_data <- function(tdw) {
  check_deweather(tdw, "tuneDeweather")
  tdw$final_fit$predictions
}
