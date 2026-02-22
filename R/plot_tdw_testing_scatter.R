#' Plot Observed vs Modelled Scatter using the 'best parameters' from
#' [tune_dw_model()]
#'
#' [tune_dw_model()] determines a 'best' set of parameters automatically and
#' models some 'final' predictions using a reserved testing dataset to evaluate
#' the model. This function produces a scatter plot (or binned variant thereof).
#'
#' @inheritParams shared_deweather_params
#' @inheritSection shared_deweather_params Plotting Engines
#'
#' @param method One of `"scatter"`, `"bin"` or `"hexbin"`.
#'
#' @param group A variable (one of the initial modelling parameters) to colour
#'   the scatter plot by. Only used when `method = "scatter"`. This could be
#'   useful to determine where the model is working most or least effectively,
#'   or to identify other patterns in the data.
#'
#' @param bins The number of bins to use when `method = "bin"` or `method =
#'   "hexbin"`.
#'
#' @param show_ablines Show 1:1, 2:1 and 1:2 lines to assist with model
#'   evaluation? Lines will appear beneath the "scatter" `method` and above
#'   either of the "bin" `method`s.
#'
#' @param show_params Show an annotation of model parameters in the top-left
#'   corner of the scatter plot?
#'
#' @param cols_ablines Colours to use for the diagonal lines, if `show_ablines =
#'   TRUE`. The the first colour is used for the 1:1 line, and the second for
#'   the 2:1 and 1:2 lines. Passed to [openair::openColours()].
#'
#' @author Jack Davison
#'
#' @examples
#' \dontrun{
#' tdw <- tune_dw_model(aqroadside, "no2", trees = c(1, 5))
#' plot_tdw_testing_scatter(tdw)
#' }
#'
#' @family Model Tuning Functions
#' @export
plot_tdw_testing_scatter <- function(
  tdw,
  method = c("scatter", "bin", "hexbin"),
  group = NULL,
  bins = 50L,
  show_ablines = TRUE,
  show_params = TRUE,
  cols = "viridis",
  cols_ablines = c("black", "grey50"),
  ...,
  .plot = TRUE,
  .plot_engine = NULL
) {
  check_deweather(tdw, "TuneDeweather")
  method <- rlang::arg_match(method)
  rlang::check_dots_empty()
  .plot_engine <- check_plot_engine(.plot_engine)

  # extract objects for plotting
  final_predictions <- get_tdw_testing_data(tdw)
  pollutant <- get_tdw_pollutant(tdw)

  # return data if not plot
  if (!.plot) {
    return(final_predictions)
  }

  # deal with group
  if (!is.null(group)) {
    opts <- names(final_predictions)
    opts <- opts[!opts %in% c("obs", "mod")]
    group <- rlang::arg_match(group, opts)
  } else {
    final_predictions$group <- factor("(all)")
    group <- "group"
  }

  # get params
  best_params_str <-
    c(
      paste0("engine: ", get_tdw_engine(tdw)),
      purrr::imap_vec(get_tdw_best_params(tdw), \(x, i) {
        lab <- x %||% "NULL"
        if (is.numeric(x)) {
          lab <- signif(x, 4)
        }
        paste0(i, ": ", lab)
      })
    ) |>
    paste(collapse = ifelse(.plot_engine == "plotly", "<br>", "\n"))

  # plot
  if (.plot_engine == "ggplot2") {
    plt <- plot_tdw_testing_scatter.ggplot2(
      tdw,
      final_predictions,
      pollutant,
      method,
      group,
      bins,
      best_params_str,
      show_params,
      show_ablines,
      cols,
      cols_ablines
    )
  }
  if (.plot_engine == "plotly") {
    plt <- plot_tdw_testing_scatter.plotly(
      tdw,
      final_predictions,
      pollutant,
      method,
      group,
      bins,
      best_params_str,
      show_params,
      show_ablines,
      cols,
      cols_ablines
    )
  }

  return(plt)
}

#' Helper for static plotting
#' @noRd
plot_tdw_testing_scatter.ggplot2 <- function(
  tdw,
  final_predictions,
  pollutant,
  method,
  group,
  bins,
  best_params_str,
  show_params,
  show_ablines,
  cols,
  cols_ablines
) {
  # need max axis range
  axisrange <- range(pretty(c(0, final_predictions$obs, final_predictions$mod)))

  # plot
  plot <- final_predictions |>
    ggplot2::ggplot(
      ggplot2::aes(x = .data$obs, y = .data$mod)
    ) +
    ggplot2::scale_x_continuous(
      limits = axisrange,
      expand = ggplot2::expansion(c(0, .1)),
      breaks = scales::pretty_breaks(6)
    ) +
    ggplot2::scale_y_continuous(
      limits = axisrange,
      expand = ggplot2::expansion(c(0, .1)),
      breaks = scales::pretty_breaks(6)
    ) +
    theme_deweather() +
    ggplot2::coord_cartesian(ratio = 1L) +
    ggplot2::labs(
      x = openair::quickText(paste("Observed", pollutant)),
      y = openair::quickText(paste("Modelled", pollutant)),
      title = openair::quickText(
        paste0(
          "R2 = ",
          round(get_tdw_testing_metrics(tdw, "r"), 2),
          ", RMSE = ",
          signif(get_tdw_testing_metrics(tdw, "rmse"), 4)
        )
      )
    )

  if (show_params) {
    plot <- plot +
      ggplot2::annotate(
        geom = "text",
        label = best_params_str,
        y = I(0.975),
        x = I(0.025),
        vjust = 1,
        hjust = 0,
        colour = "grey25"
      )
  }

  if (method == "scatter") {
    if (show_ablines) {
      plot <- plot + annotate_ablines.ggplot2(cols_ablines)
    }

    plot <-
      plot +
      ggplot2::geom_point(
        ggplot2::aes(colour = .data[[group]]),
        show.legend = dplyr::n_distinct(final_predictions[[group]]) > 1L
      )

    if (is.factor(final_predictions[[group]])) {
      plot <- plot +
        ggplot2::scale_colour_manual(
          values = openair::openColours(
            cols,
            n = dplyr::n_distinct(final_predictions[[group]])
          )
        )
    } else {
      plot <- plot +
        ggplot2::scale_color_gradientn(
          colours = openair::openColours(cols)
        )
    }
  }

  if (method %in% c("bin", "hexbin")) {
    if (method == "hexbin") {
      plot <- plot + ggplot2::geom_hex(bins = bins)
    }

    if (method == "bin") {
      plot <- plot + ggplot2::geom_bin_2d(bins = bins)
    }

    plot <- plot +
      ggplot2::scale_fill_gradientn(
        colours = openair::openColours(cols)
      )

    if (show_ablines) {
      plot <- plot + annotate_ablines.ggplot2(cols_ablines)
    }
  }

  return(plot)
}

#' @noRd
annotate_ablines.ggplot2 <- function(colour = "black") {
  cols <- openair::openColours(colour, n = 2)
  list(
    ggplot2::geom_abline(
      color = cols[2],
      alpha = 0.5,
      lty = 5,
      slope = 0.5,
      lwd = 0.5
    ),
    ggplot2::geom_abline(
      color = cols[2],
      alpha = 0.5,
      lty = 5,
      slope = 2.0,
      lwd = 0.5
    ),
    ggplot2::geom_abline(
      color = cols[1],
      alpha = 1.0,
      lty = 1,
      slope = 1.0,
      lwd = 1
    )
  )
}

#' Helper for static plotting
#' @noRd
plot_tdw_testing_scatter.plotly <- function(
  tdw,
  final_predictions,
  pollutant,
  method,
  group,
  bins,
  best_params_str,
  show_params,
  show_ablines,
  cols,
  cols_ablines
) {
  # need max axis range
  axisrange <- range(pretty(c(0, final_predictions$obs, final_predictions$mod)))

  if (method == "scatter") {
    if (is.numeric(final_predictions[[group]])) {
      colors <- openair::openColours(cols)
    } else {
      colors <- openair::openColours(
        cols,
        n = dplyr::n_distinct(final_predictions[[group]])
      )
    }

    plot <-
      plotly::plot_ly(
        final_predictions,
        x = final_predictions$obs,
        y = final_predictions$mod,
        color = final_predictions[[group]],
        colors = colors
      ) |>
      annotate_ablines.plotly(axisrange, cols_ablines) |>
      plotly::add_markers(name = " ") |>
      plotly::layout(
        legend = list(
          title = list(
            text = group
          )
        )
      )
  } else {
    if (method == "hexbin") {
      cli::cli_warn(c(
        "!" = "{.arg method} 'hexbin' is not currently supported by the 'plotly' plotting engine.",
        "i" = "Using 'bin' method instead."
      ))
    }

    bin_to_midpoint <- function(x, nbins) {
      x_range <- range(x, na.rm = TRUE)
      breaks <- seq(x_range[1], x_range[2], length.out = nbins + 1)
      bins <- cut(x, breaks = breaks, include.lowest = TRUE, labels = FALSE)
      midpoints <- (breaks[-length(breaks)] + breaks[-1]) / 2
      midpoints[bins]
    }

    counts <-
      final_predictions |>
      dplyr::mutate(
        obs = bin_to_midpoint(.data$obs, bins),
        mod = bin_to_midpoint(.data$mod, bins)
      ) |>
      dplyr::count(.data$obs, .data$mod)

    plot <- plotly::plot_ly(
      counts,
      x = counts$obs,
      y = counts$mod,
      z = counts$n,
      colors = openair::openColours(cols),
      colorbar = list(
        title = "Count"
      )
    ) |>
      plotly::add_heatmap(name = " ") |>
      annotate_ablines.plotly(axisrange, cols_ablines)
  }

  plot <- plot |>
    plotly::layout(
      xaxis = list(
        range = axisrange,
        title = paste("Observed", toupper(pollutant)),
        constrain = "domain"
      ),
      yaxis = list(
        range = axisrange,
        title = paste("Modelled", toupper(pollutant)),
        constrain = "domain",
        scaleanchor = "x",
        scaleratio = 1
      ),
      title = paste0(
        "R<sup>2</sup> = ",
        round(get_tdw_testing_metrics(tdw, "r"), 2),
        ", RMSE = ",
        signif(get_tdw_testing_metrics(tdw, "rmse"), 4)
      )
    )

  if (show_params) {
    plot <- plot |>
      plotly::add_annotations(
        text = best_params_str,
        y = 0.775,
        x = 0.15,
        yref = "y domain",
        xref = "x domain",
        align = "left",
        valign = "top",
        bgcolor = "#FFFFFFE6",
        bordercolor = "black",
        borderpad = 5
      )
  }

  return(plot)
}

#' @noRd
annotate_ablines.plotly <- function(plot, axisrange, cols_ablines) {
  abline_cols <- openair::openColours(cols_ablines, n = 2)

  plot |>
    # 1:1 line (solid)
    plotly::add_segments(
      x = axisrange[1],
      xend = axisrange[2],
      y = axisrange[1],
      yend = axisrange[2],
      line = list(color = abline_cols[1], width = 2),
      showlegend = FALSE,
      inherit = FALSE,
      hoverinfo = "none"
    ) |>
    # 2:1 line (dotted) - y = 2x
    plotly::add_segments(
      x = axisrange[1],
      xend = axisrange[2],
      y = axisrange[1] * 2,
      yend = axisrange[2] * 2,
      line = list(color = abline_cols[2], width = 1, dash = "dot"),
      showlegend = FALSE,
      inherit = FALSE,
      hoverinfo = "none"
    ) |>
    # 1:2 line (dotted) - y = x/2
    plotly::add_segments(
      x = axisrange[1],
      xend = axisrange[2],
      y = axisrange[1] / 2,
      yend = axisrange[2] / 2,
      line = list(color = abline_cols[2], width = 1, dash = "dot"),
      showlegend = FALSE,
      inherit = FALSE,
      hoverinfo = "none"
    )
}
