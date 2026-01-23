#' Plot Observed vs Modelled Scatter using the 'best parameters' from
#' [tune_dw_model()]
#'
#' [tune_dw_model()] determines a 'best' set of parameters automatically and
#' models some 'final' predictions using a reserved testing dataset to evaluate
#' the model. This function produces a scatter (or varient)
#'
#' @param tdw A deweather tuning object created with [tune_dw_model()].
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
#' @param cols Colours to use for plotting. See [openair::openColours()].
#'
#' @param cols_ablines Colours to use for the diagonal lines, if `show_ablines =
#'   TRUE`. The the first colour is used for the 1:1 line, and the second for
#'   the 2:1 and 1:2 lines. Passed to [openair::openColours()].
#'
#' @family Model Tuning Functions
#' @export
plot_tdw_scatter <- function(
  tdw,
  method = c("scatter", "bin", "hexbin"),
  group = NULL,
  bins = 50L,
  show_ablines = TRUE,
  show_params = TRUE,
  cols = "viridis",
  cols_ablines = c("black", "grey50")
) {
  check_deweather(tdw, "tuneDeweather")
  method <- rlang::arg_match(method)

  # extract objects for plotting
  final_predictions <- get_tdw_testing_data(tdw)
  pollutant <- get_tdw_pollutant(tdw)

  # need max axis range
  axisrange <- range(pretty(c(0, final_predictions$obs, final_predictions$mod)))

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
        paste0(i, ": ", x %||% "NULL")
      })
    ) |>
    paste(collapse = "\n")

  # plot
  plot <- final_predictions |>
    ggplot2::ggplot(
      ggplot2::aes(x = .data$obs, y = .data$mod)
    ) +
    ggplot2::scale_x_continuous(
      limits = axisrange,
      expand = ggplot2::expansion(c(0, .1))
    ) +
    ggplot2::scale_y_continuous(
      limits = axisrange,
      expand = ggplot2::expansion(c(0, .1))
    ) +
    ggplot2::theme_bw() +
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
      plot <- plot + annotate_ablines(cols_ablines)
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
      plot <- plot + annotate_ablines(cols_ablines)
    }
  }

  return(plot)
}

#' @noRd
annotate_ablines <- function(colour = "black") {
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
