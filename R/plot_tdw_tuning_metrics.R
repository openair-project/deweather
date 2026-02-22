#' Plot Tuning Metrics from [tune_dw_model()]
#'
#' This function creates a plot of the tuning metrics from a `TuneDeweather`
#' object created using [tune_dw_model()]. It visualises how different
#' hyperparameter values affect model performance (RMSE and RSQ). This allows
#' for the 'best' parameters to be refined through visual inspection. This plot
#' is likely most effective with between 1 and 3 simultaneously tuned
#' parameters; any more will impede plot interpretation.
#'
#' @inheritParams shared_deweather_params
#' @inheritSection shared_deweather_params Plotting Engines
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
#' @author Jack Davison
#'
#' @examples
#' \dontrun{
#' tdw <- tune_dw_model(aqroadside, "no2", trees = c(1, 5))
#' plot_tdw_tuning_metrics(tdw)
#' }
#'
#' @family Model Tuning Functions
#' @export
plot_tdw_tuning_metrics <- function(
  tdw,
  x = NULL,
  group = NULL,
  facet = NULL,
  show_std_err = TRUE,
  cols = "tol",
  ...,
  .plot = TRUE,
  .plot_engine = NULL
) {
  check_deweather(tdw, "TuneDeweather")
  rlang::check_dots_empty()
  .plot_engine <- check_plot_engine(.plot_engine)

  metrics <- get_tdw_tuning_metrics(tdw)

  if (!.plot) {
    return(metrics)
  }

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
    rounded <- round_unique(metrics[[group]])
    metrics[group] <- factor(
      rounded,
      levels = as.character(sort(unique(rounded)))
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
    rounded <- round_unique(metrics[[facet]])
    metrics[facet] <- factor(
      rounded,
      levels = as.character(sort(unique(rounded)))
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

  if (.plot_engine == "ggplot2") {
    plt <- plot_tdw_tuning_metrics.ggplot2(
      metrics,
      x,
      group,
      facet,
      cols,
      show_std_err
    )
  }

  if (.plot_engine == "plotly") {
    plt <- plot_tdw_tuning_metrics.plotly(
      metrics,
      x,
      group,
      facet,
      cols,
      show_std_err
    )
  }

  return(plt)
}

# helper for static plotting
plot_tdw_tuning_metrics.ggplot2 <- function(
  metrics,
  x,
  group,
  facet,
  cols,
  show_std_err
) {
  # geom for points
  if (show_std_err) {
    pointgeom <- ggplot2::geom_pointrange
  } else {
    pointgeom <- ggplot2::geom_point
    metrics$std_err <- 0
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
    ggplot2::labs(
      y = NULL
    ) +
    theme_deweather() +
    ggplot2::scale_y_continuous(
      breaks = scales::pretty_breaks(6)
    ) +
    ggplot2::scale_color_manual(
      values = openair::openColours(
        cols,
        n = dplyr::n_distinct(metrics[[group]])
      )
    )

  # most metrics are numeric, but a few aren't (e.g., splitrule in ranger)
  if (is.numeric(metrics[[x]])) {
    widths <- diff(unique(metrics[[x]])) / 2
    pos <- ggplot2::position_dodge2(width = widths[1])

    plt <- plt +
      ggplot2::geom_line(
        show.legend = FALSE,
        position = pos,
        alpha = ifelse(show_std_err, 0.3, 1)
      ) +
      pointgeom(
        show.legend = dplyr::n_distinct(metrics[[group]]) > 1L,
        position = pos
      )
  } else {
    pos <- ggplot2::position_dodge2(width = 0.5)
    plt <- plt +
      pointgeom(
        show.legend = dplyr::n_distinct(metrics[[group]]) > 1L,
        position = pos
      )
  }

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

# helper for dynamic plotting
plot_tdw_tuning_metrics.plotly <- function(
  metrics,
  x,
  group,
  facet,
  cols,
  show_std_err
) {
  create_metric_panel <- function(m) {
    df <- metrics[metrics$metric == m, ]
    plot <- plotly::plot_ly(
      showlegend = dplyr::n_distinct(df[[group]]) > 1L,
      colors = openair::openColours(
        scheme = cols,
        n = dplyr::n_distinct(df[[group]])
      )
    ) |>
      plotly::layout(
        yaxis = list(
          title = m
        ),
        xaxis = list(
          title = x
        ),
        hovermode = "x unified"
      )

    for (i in unique(df$metric_group)) {
      df_i <- df[df$metric_group == i, ]

      error_y <- list()
      if (show_std_err) {
        error_y <- list(array = df_i$std_err)
      }

      plot <- plot |>
        plotly::add_lines(
          x = df_i[[x]],
          y = df_i$mean,
          color = df_i[[group]],
          hoverinfo = "none",
          showlegend = FALSE,
          legendgroup = df_i[[group]]
        ) |>
        plotly::add_markers(
          x = df_i[[x]],
          y = df_i$mean,
          color = df_i[[group]],
          error_y = error_y,
          legendgroup = df_i[[group]],
          showlegend = m == "RSQ"
        )
    }

    return(plot)
  }

  plotly::subplot(
    create_metric_panel("RMSE"),
    create_metric_panel("RSQ"),
    nrows = 1,
    shareX = TRUE,
    titleX = TRUE,
    titleY = TRUE,
    margin = 0.05
  )
}

# Helper function to round numbers ensuring unique values remain unique
round_unique <- function(x, min_digits = 2) {
  if (is.null(x)) {
    return(x)
  }
  x_unique <- unique(x)
  digits <- max(min_digits, ceiling(-log10(diff(range(x_unique))) + 1))
  round(x, digits)
}
