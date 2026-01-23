#' Plot Tuning Metrics from [tune_dw_model()]
#'
#' This function creates a plot of the tuning metrics from a `tuneDeweather`
#' object created using [tune_dw_model()]. It visualises how different
#' hyperparameter values affect model performance (RMSE and RSQ). This allows
#' for the 'best' parameters to be refined through visual inspection. This plot
#' is likely most effective with between 1 and 3 simultaneously tuned
#' parameters; any more will impede plot interpretation.
#'
#' @param tdw A deweather tuning object created with [tune_dw_model()].
#'
#' @param x The tuned parameter to plot on the x-axis. If not selected, the
#'   first parameter in the `metrics` dataset will be chosen.
#'
#' @param group,facet Additional tuned parameters other than `x`, used to
#'   further control the plot. `group` colours the plot by another parameter,
#'   and `facet` splits the diagram into additional panels. Neither `group` nor
#'   `facet` can be the same parameter as `x`.
#'
#' @param show_std_err Show the standard error using error bars?
#'
#' @param cols Colours to use for plotting. See [openair::openColours()].
#'
#' @author Jack Davison
#' @family Model Tuning Functions
#' @export
plot_tdw_metrics <- function(
  tdw,
  x = NULL,
  group = NULL,
  facet = NULL,
  show_std_err = TRUE,
  cols = "Set1"
) {
  check_deweather(tdw, "tuneDeweather")

  metrics <- get_tdw_tuning_metrics(tdw)
  metrics$metric <- toupper(metrics$metric)

  best_params_names <- names(get_tdw_best_params(tdw))
  varied_params <- best_params_names[best_params_names %in% names(metrics)]

  x <- x %||% varied_params[1]

  x <- rlang::arg_match(x, varied_params)

  if (is.null(group)) {
    metrics$group <- factor("(all)")
    group <- "group"
  } else {
    if (group == x) {
      cli::cli_abort("{.arg group} cannot be the same as {.arg x}.")
    }
    group <- rlang::arg_match(group, varied_params)
    metrics[group] <- factor(
      metrics[[group]],
      levels = as.character(sort(unique(metrics[[group]])))
    )
  }

  if (is.null(facet)) {
    metrics$facet <- factor("(all)")
    facet <- "facet"
  } else {
    if (facet == x) {
      cli::cli_abort("{.arg facet} cannot be the same as {.arg x}.")
    }
    facet <- rlang::arg_match(facet, varied_params)
    metrics[facet] <- factor(
      metrics[[facet]],
      levels = as.character(sort(unique(metrics[[facet]])))
    )
  }

  # combine the group params columns (arbitrary number) into one column
  group_params <- varied_params[varied_params != x]
  if (length(group_params) > 0L) {
    metrics$metric_group <- apply(
      metrics[, group_params, drop = FALSE],
      1,
      paste,
      collapse = "_"
    )
  } else {
    metrics$metric_group <- "(all)"
  }

  # nice spacing for dodging
  widths <- diff(unique(metrics[[x]])) / 2
  pos <- ggplot2::position_dodge2(width = widths[1])

  # geom for points
  if (show_std_err) {
    pointgeom <- ggplot2::geom_pointrange
  } else {
    pointgeom <- ggplot2::geom_point
  }

  # make plot
  plt <- ggplot2::ggplot(
    metrics,
    ggplot2::aes(
      x = .data[[x]],
      y = .data$mean,
      ymin = .data$mean - .data$std_err,
      ymax = .data$mean + .data$std_err,
      colour = .data[[group]],
      group = .data$metric_group
    )
  ) +
    ggplot2::geom_line(
      show.legend = FALSE,
      position = pos,
      alpha = ifelse(show_std_err, 0.3, 1)
    ) +
    pointgeom(
      show.legend = dplyr::n_distinct(metrics[[group]]) > 1L,
      position = pos
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(strip.background = ggplot2::element_blank()) +
    ggplot2::scale_color_manual(
      values = openair::openColours(
        cols,
        n = dplyr::n_distinct(metrics[[group]])
      )
    )

  # facet
  if (dplyr::n_distinct(metrics[[facet]]) > 1L) {
    plt <- plt +
      ggplot2::facet_grid(
        rows = ggplot2::vars(.data$metric),
        cols = ggplot2::vars(.data[[facet]]),
        scales = "free_y",
        labeller = ggplot2::label_both
      )
  } else {
    plt <- plt +
      ggplot2::facet_wrap(
        ggplot2::vars(.data$metric),
        scales = "free_y",
        labeller = ggplot2::label_both
      )
  }

  # return
  return(plt)
}
