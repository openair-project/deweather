#' Use a deweather model to predict with a new dataset
#'
#' This function is a convenient wrapper around [parsnip::predict.model_fit()]
#' to use a deweather model for prediction. This automatically extracts relevant
#' parts of the deweather object and creates variables within `newdata` using
#' [append_dw_vars()] if required.
#'
#' @inheritParams shared_deweather_params
#'
#' @param newdata Data set to which to apply the model. If missing the data used
#'   to build the model in the first place will be used.
#'
#' @param name The name of the new column.
#'
#' @param column_bind If `TRUE`, this function will return `newdata` with an
#'   additional prediction column bound to it. If `FALSE`, return a
#'   single-column data frame.
#'
#' @export
#'
#' @return a [tibble][tibble::tibble-package]
#'
#' @examples
#' \dontrun{
#' dw <- build_dw_model(aqroadside, "no2")
#' pred <- predict_dw(dw)
#' }
#'
#' @author Jack Davison
predict_dw <- function(
  dw,
  newdata = deweather::get_dw_input_data(dw),
  name = deweather::get_dw_pollutant(dw),
  column_bind = FALSE
) {
  check_deweather(dw)

  # get model components
  mod <- get_dw_model(dw)
  vars <- get_dw_vars(dw)

  # if any of the vars given aren't in data, they can be appended by the
  # append_dw_vars function
  if (any(!vars %in% names(newdata))) {
    vars_to_add <- vars[!vars %in% names(newdata)]
    newdata <- append_dw_vars(newdata, vars = vars_to_add, abbr = TRUE)
  }

  # don't allow overwriting columns
  if (name %in% names(newdata) && column_bind) {
    cli::cli_abort(
      "'{name}' already present in {.arg newdata}; change {.arg name} or set {.arg column_bind} to {FALSE}."
    )
  }

  # predict
  prediction <- parsnip::predict.model_fit(
    mod,
    new_data = newdata,
    type = "numeric"
  ) |>
    stats::setNames(name)

  if (column_bind) {
    prediction <- dplyr::bind_cols(newdata, prediction)
  }

  return(prediction)
}
