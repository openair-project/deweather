#' Visualise deweather model feature importance
#'
#' Visualise the feature importance (% Gain for boosted tree models) for each
#' variable of a deweather model, with some customisation.
#'
#' @inheritParams get_dw_importance
#'
#' @param cols Colours to use for plotting. See [openair::openColours()].
#'
#' @return a [ggplot2][ggplot2::ggplot2-package] figure
#'
#' @export
plot_dw_importance <-
  function(dw, aggregate_factors = FALSE, sort = TRUE, cols = "tol") {
    check_deweather(dw)
    importance <-
      get_dw_importance(dw, aggregate_factors = aggregate_factors, sort = sort)

    ggplot2::ggplot(
      importance,
      ggplot2::aes(x = .data[["importance"]], y = .data[["var"]])
    ) +
      ggplot2::geom_col(fill = openair::openColours(cols, n = 1L)) +
      ggplot2::scale_x_continuous(
        expand = ggplot2::expansion(c(0, .1)),
        labels = function(x) {
          paste0(x * 100, "%")
        }
      ) +
      ggplot2::scale_y_discrete(
        labels = \(x) sapply(x, openair::quickText)
      ) +
      ggplot2::labs(y = NULL, x = "Importance") +
      ggplot2::theme_bw()
  }

#' Take an importance dataframe and combine factor variables into a single
#' feature
#' @param importance,vars,data Consistent with previous data
#' @noRd
aggregate_importance_factors <- function(dw) {
  importance <- get_dw_importance(dw, aggregate_factors = FALSE)
  vars <- get_dw_vars(dw)
  data <- get_dw_input_data(dw)

  # if nrow(importance) is the same as length of vars, there's nothing to
  # aggregate
  if (nrow(importance) == length(vars)) {
    return(importance)
  }

  # get the types of each variable
  vartypes <-
    purrr::map_vec(vars, function(x) {
      class(data[[x]])
    })

  # get the factor variables
  factor_vars <- vars[vartypes == "factor"]

  # create a dictionary of non-factors (newFeature is the same)
  dict <- data.frame(
    newFeature = vars[vartypes != "factor"],
    var = vars[vartypes != "factor"]
  )

  # if there are any factor vars, append these to the dictionary
  if (length(factor_vars) > 0L) {
    dict <-
      dplyr::bind_rows(
        dict,
        purrr::map(
          factor_vars,
          function(x) {
            data.frame(
              newFeature = x,
              var = paste0(x, levels(data[[x]]))
            )
          }
        ) |>
          dplyr::bind_rows()
      )
  }

  # summarise per new Feature
  importance <-
    dplyr::left_join(importance, dict, by = dplyr::join_by("var")) |>
    dplyr::summarise(importance = sum(.data$importance), .by = "newFeature") |>
    dplyr::rename(var = "newFeature") |>
    dplyr::arrange(dplyr::desc(.data$importance))

  # restore correct factor order
  importance$var <-
    factor(importance$var, rev(importance$var))

  return(importance)
}
