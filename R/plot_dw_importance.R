#' Visualise deweather model feature importance
#'
#' Visualise the feature importance (% Gain for boosted tree models, permutation
#' importance for random forest models) for each variable of a deweather model
#' as a bar chart, with some customisation.
#'
#' @inheritParams get_dw_importance
#' @inheritParams shared_deweather_params
#' @inheritSection shared_deweather_params Plotting Engines
#'
#' @return a [ggplot2][ggplot2::ggplot2-package] figure
#'
#' @export
plot_dw_importance <-
  function(
    dw,
    aggregate_factors = FALSE,
    sort = TRUE,
    cols = "tol",
    ...,
    .plot = TRUE,
    .plot_engine = NULL
  ) {
    check_deweather(dw)
    .plot_engine <- check_plot_engine(.plot_engine)

    importance <-
      get_dw_importance(dw, aggregate_factors = aggregate_factors, sort = sort)

    if (!.plot) {
      return(importance)
    }

    if (.plot_engine == "ggplot2") {
      plt <- plot_dw_importance.ggplot2(dw, importance, cols)
    }
    if (.plot_engine == "plotly") {
      plt <- plot_dw_importance.plotly(dw, importance, cols)
    }

    return(plt)
  }

# Helper for static importance plot
plot_dw_importance.ggplot2 <- function(dw, importance, cols) {
  scale_fun <- if (dw$engine$method == "boost_tree") {
    scales::label_percent()
  } else {
    scales::label_comma()
  }

  ggplot2::ggplot(
    importance,
    ggplot2::aes(x = .data[["importance"]], y = .data[["var"]])
  ) +
    ggplot2::geom_col(fill = openair::openColours(cols, n = 1L)) +
    ggplot2::scale_x_continuous(
      expand = ggplot2::expansion(c(0, .1)),
      breaks = scales::pretty_breaks(6),
      labels = scale_fun
    ) +
    ggplot2::scale_y_discrete(
      labels = \(x) sapply(x, openair::quickText)
    ) +
    ggplot2::labs(y = NULL, x = "Importance") +
    theme_deweather("x")
}

# Helper for interactive importance plot
plot_dw_importance.plotly <- function(dw, importance, cols) {
  plotly::plot_ly(
    importance,
    x = importance[["importance"]],
    y = importance[["var"]],
    color = "importance",
    colors = openair::openColours(cols, n = 1)
  ) |>
    plotly::add_bars() |>
    plotly::layout(
      margin = list(
        pad = 10
      ),
      yaxis = list(
        title = ""
      ),
      xaxis = list(
        title = "Importance",
        tickformat = ifelse(dw$engine$method == "boost_tree", ".0%", "")
      )
    )
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
