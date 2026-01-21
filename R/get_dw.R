#' Getters for various deweather model features
#'
#' @description
#'
#' `deweather` provides multiple 'getter' functions for extracting relevant
#' model features from a deweather model. These are a useful convenience,
#' particularly in conjunction with R's [pipe][pipeOp] operator (`|>`).
#'
#' @param dw A deweather model created with [build_dw_model()].
#'
#' @param param For [get_dw_params()]. The default (`NULL`) returns a list of
#'   model parameters. `param` will return one specific parameter as a character
#'   vector.
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
#' @order 4
#' @export
get_dw_input_data <- function(dw) {
  check_deweather(dw)
  dw$data$input
}

#' @rdname getters-dw
#' @order 5
#' @export
get_dw_model <- function(dw) {
  check_deweather(dw)
  dw$model
}

#' @rdname getters-dw
#' @order 6
#' @export
get_dw_engine <- function(dw) {
  check_deweather(dw)
  dw$engine$engine
}


#' @rdname getters-dw
#' @export
#' @order 7
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
