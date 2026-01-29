#' Plot a simulated 'deweathered' trend, optionally with its input data
#'
#' This function conveniently plots the trend from a simulated deweathered time
#' series, with the option to overlay the trend from the original input data.
#' The data can also be averaged over specified time intervals for clearer
#' visualisation.
#'
#' @inheritParams shared_deweather_params
#' @inheritSection shared_deweather_params Plotting Engines
#'
#' @param sim The output of [simulate_dw_met()]; a `data.frame` with first
#'   column `date` and second column a numeric pollutant.
#'
#' @param dw Optionally, the input model used to construct `sim`. If provided,
#'   the original timeseries will be plotted alongside the simulated trend for
#'   easy comparison.
#'
#' @param ylim The limits of the y-axis.
#'
#' @param avg.time Passed to [openair::timeAverage()].
#'
#' @param names A character vector of length two, used to label the simulated
#'   dataset and the original dataset.
#'
#' @author Jack Davison
#' @export
plot_sim_trend <- function(
  sim,
  dw = NULL,
  avg.time = NULL,
  ylim = NULL,
  names = c("Met Simulation", "Original Data"),
  cols = "tol",
  ...,
  .plot = TRUE,
  .plot_engine = NULL
) {
  rlang::check_dots_empty()
  .plot_engine <- check_plot_engine(.plot_engine)
  if (!is.null(dw)) {
    check_deweather(dw)
  }

  sim_name <- names[1]
  dat_name <- names[2]

  sim <- dplyr::mutate(sim, .id = sim_name, .before = 0)

  pollutant <- names(sim)[3]

  if (!is.null(dw)) {
    input_data <- get_dw_input_data(dw)

    if (!"trend" %in% names(input_data)) {
      cli::cli_abort(
        "To plot a comparison between simulated and raw data, 'trend' must be a component."
      )
    }

    input_data <-
      input_data |>
      dplyr::select(dplyr::all_of(c("trend", pollutant))) |>
      dplyr::mutate(
        trend = as.POSIXct(.data$trend, tz = dw$tz)
      ) |>
      dplyr::rename("date" = "trend") |>
      dplyr::mutate(
        .id = dat_name,
        .before = 0L
      )

    sim <- dplyr::bind_rows(
      sim,
      input_data
    ) |>
      dplyr::mutate(
        .id = factor(.data$.id, c(dat_name, sim_name))
      )
  }

  if (!is.null(avg.time)) {
    sim <- openair::timeAverage(
      sim,
      avg.time = avg.time,
      type = ".id",
      progress = FALSE
    )
  }

  if (!.plot) {
    return(sim)
  }

  if (.plot_engine == "ggplot2") {
    plt <- plot_sim_trend.ggplot2(sim, pollutant, ylim, cols)
  }

  if (.plot_engine == "plotly") {
    plt <- plot_sim_trend.plotly(sim, pollutant, ylim, cols)
  }

  return(plt)
}

plot_sim_trend.ggplot2 <- function(sim, pollutant, ylim, cols) {
  ggplot2::ggplot(
    sim,
    ggplot2::aes(x = .data$date, y = .data[[pollutant]], color = .data$.id)
  ) +
    ggplot2::geom_line(show.legend = dplyr::n_distinct(sim$.id) > 1) +
    ggplot2::labs(
      x = NULL,
      y = openair::quickText(pollutant),
      color = NULL
    ) +
    ggplot2::coord_cartesian(
      ylim = ylim
    ) +
    ggplot2::scale_color_manual(
      values = openair::openColours(cols, n = dplyr::n_distinct(sim$.id))
    ) +
    ggplot2::scale_x_datetime(
      breaks = scales::pretty_breaks(8),
      expand = ggplot2::expansion()
    ) +
    ggplot2::scale_y_continuous(
      breaks = scales::pretty_breaks(6),
      expand = ggplot2::expansion(c(0, .1))
    ) +
    theme_deweather(legend.position = "top", legend.justification = "left")
}

plot_sim_trend.plotly <- function(sim, pollutant, ylim, cols) {
  plotly::plot_ly(
    sim,
    x = sim$date,
    y = sim[[pollutant]],
    color = sim$.id,
    colors = openair::openColours(cols, n = dplyr::n_distinct(sim$.id)),
    showlegend = dplyr::n_distinct(sim$.id) > 1
  ) |>
    plotly::add_lines() |>
    plotly::layout(
      yaxis = list(
        title = toupper(pollutant),
        range = ylim,
        fixedrange = FALSE
      ),
      xaxis = list(
        title = " "
      ),
      legend = list(
        y = 1.2,
        orientation = "h"
      ),
      hovermode = "x unified"
    ) |>
    plotly::rangeslider()
}
