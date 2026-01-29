#' Create a 2-way partial dependence plot for deweather models
#'
#' Generates 2-way partial dependence plot to visualize the relationship between
#' two predictor variables and model predictions. These plots show how the
#' predicted pollutant concentration changes as a function of two variables
#' while averaging over the effects of all other variables.
#'
#' @inheritParams plot_dw_partial_1d
#' @inheritParams shared_deweather_params
#' @inheritSection shared_deweather_params Plotting Engines
#'
#' @param var_x,var_y The name of the two variables to plot. Must be one of the
#'   variables used in the model. If both are missing, the top two most
#'   individually important numeric variables will be selected automatically.
#'
#' @param contour Show contour lines on the plot? Can be one of `"none"` (the
#'   default, no contour lines), `"lines"` (draws lines) or `"fill"` (draws
#'   filled contours using a binned colour scale).
#'
#' @param contour_bins How many bins should be drawn if `contour != "none"`?
#'
#' @param show_conf_int Should the bootstrapped 95% confidence interval be
#'   shown? In [plot_dw_partial_2d()] this creates separate facets for the lower
#'   and higher confidence intervals. It may be easiest to see the difference by
#'   using `contour = "fill"`.
#'
#' @param exclude_distance A 2-way partial dependence plot uses
#'   [mgcv::exclude.too.far()] to ensure the plotted surface is within range of
#'   the original input data. `exclude_distance` defines how far away from the
#'   original data is too far to plot. This should be in the range `0` to `1`,
#'   where higher values are more permissive; `1` will retain all data.
#'
#' @param radial_wd Should the `"wd"` (wind direction) variable be plotted on a
#'   radial axis? This can enhance interpretability, but makes it inconsistent
#'   with other variables which are plotted on cartesian coordinates. Defaults
#'   to `FALSE`.
#'
#' @return A `ggplot2` object showing the partial dependence plot. If `plot =
#'   FALSE`, a named list of plot data will be returned instead.
#'
#' @export
plot_dw_partial_2d <- function(
  dw,
  var_x = NULL,
  var_y = NULL,
  intervals = 40L,
  contour = c("none", "lines", "fill"),
  contour_bins = 8,
  exclude_distance = 0.05,
  show_conf_int = FALSE,
  n = NULL,
  prop = 0.01,
  cols = "viridis",
  radial_wd = FALSE,
  ...,
  .plot = TRUE,
  .plot_engine = NULL,
  .progress = rlang::is_interactive()
) {
  check_deweather(dw)
  rlang::check_dots_empty()
  .plot_engine <- check_plot_engine(.plot_engine)

  if (exclude_distance < 0 || exclude_distance > 1) {
    cli::cli_abort("{.arg exclude_distance} must be between {0} and {1}.")
  }

  # get model features
  model <- get_dw_model(dw)
  vars <- get_dw_vars(dw)
  input_data <- get_dw_input_data(dw)
  pollutant <- get_dw_pollutant(dw)
  importance <- get_dw_importance(dw, aggregate_factors = TRUE)

  # if vars are missing, pick the two most important numeric variables
  if (is.null(var_x) && is.null(var_y)) {
    num_vars <- dw$vars$names[dw$vars$types %in% c("numeric", "integer")]
    most_important <-
      importance |>
      dplyr::filter(.data$var %in% num_vars) |>
      dplyr::slice_head(n = 2L) |>
      dplyr::pull(.data$var) |>
      as.character()
    var_x <- most_important[1]
    var_y <- most_important[2]
  }

  # make sure vars are model vars
  var_x <- rlang::arg_match(var_x, vars)
  var_y <- rlang::arg_match(var_y, vars)
  contour <- rlang::arg_match(
    contour,
    c("none", "lines", "fill"),
    multiple = FALSE
  )

  # check vars don't conflict
  if (var_x == var_y) {
    cli::cli_abort("{.arg var_x} cannot be the same as {.arg var_y}.")
  }

  if (var_x == "trend" || var_y == "trend") {
    cli::cli_abort(
      "{.fun deweather::plot_dw_partial_2d} does not support the 'trend' variable."
    )
  }

  # need to switch around the variables if radial_wd is desired
  if (radial_wd && (var_x == "wd" || var_y == "wd")) {
    if (var_y == "wd") {
      var_y <- var_x
      var_x <- "wd"
    }
  }

  # rows to use in data
  rows <- sample(
    x = nrow(input_data),
    size = n %||% round(prop * nrow(input_data)),
    replace = FALSE
  )
  obs_df <- input_data[rows, ]

  # get 2d CP
  cp2d <-
    cp_profiles(
      dw = dw,
      obs = obs_df,
      var_x = var_x,
      var_y = var_y,
      intervals = intervals,
      progress = .progress
    )

  # calculate mean
  plotdata <-
    dplyr::reframe(
      cp2d,
      openair::bootMeanDF(.data[[pollutant]], B = 100),
      .by = dplyr::all_of(c(var_x, var_y))
    )

  # exclude too far
  if (is.numeric(plotdata[[var_x]]) && is.numeric(plotdata[[var_y]])) {
    id <- mgcv::exclude.too.far(
      d1 = input_data[[var_x]],
      d2 = input_data[[var_y]],
      g1 = plotdata[[var_x]],
      g2 = plotdata[[var_y]],
      dist = exclude_distance
    )
    plotdata <- plotdata[!id, ]
  }

  # if not plotting, just return the data
  if (!.plot) {
    return(plotdata)
  }

  if (.plot_engine == "ggplot2") {
    plt <- plot_dw_partial_2d.ggplot2(
      plotdata,
      var_x,
      var_y,
      pollutant,
      contour,
      contour_bins,
      cols,
      show_conf_int,
      radial_wd
    )
  }

  if (.plot_engine == "plotly") {
    plt <- plot_dw_partial_2d.plotly(
      plotdata,
      var_x,
      var_y,
      pollutant,
      contour,
      contour_bins,
      cols,
      show_conf_int,
      radial_wd
    )
  }

  return(plt)
}

# helper for static plot
plot_dw_partial_2d.ggplot2 <- function(
  plotdata,
  var_x,
  var_y,
  pollutant,
  contour,
  contour_bins,
  cols,
  show_conf_int,
  radial_wd
) {
  # if plotting confidence interval, need to reshape data and define a faceting
  # strategy
  if (show_conf_int) {
    plotdata <-
      plotdata |>
      tidyr::pivot_longer(
        cols = c("mean", "min", "max"),
        values_to = "mean",
        names_to = "stat"
      ) |>
      dplyr::mutate(
        stat = factor(
          .data$stat,
          levels = c("min", "mean", "max"),
          labels = c("Lower 95% CI", "Mean", "Upper 95% CI")
        )
      )
    facet <- ggplot2::facet_wrap(
      ggplot2::vars(.data$stat),
      nrow = 1L,
      axes = "all"
    )
  } else {
    facet <- NULL
  }

  scale_x <- NULL
  scale_y <- NULL
  if (var_x == "wd" && !radial_wd) {
    scale_x <- wd_scale("x")
  }
  if (var_y == "wd" && !radial_wd) {
    scale_y <- wd_scale("y")
  }
  if (var_x == "hour") {
    scale_x <- hour_scale("x")
  }
  if (var_y == "hour") {
    scale_y <- hour_scale("y")
  }

  # make plot
  plot <- ggplot2::ggplot(
    plotdata,
    ggplot2::aes(x = .data[[var_x]], y = .data[[var_y]])
  ) +
    ggplot2::labs(
      x = openair::quickText(var_x),
      y = openair::quickText(var_y),
      fill = openair::quickText(pollutant)
    ) +
    theme_deweather(
      axis.line.x.bottom = ggplot2::element_line(),
      axis.line.y.left = ggplot2::element_line()
    ) +
    facet +
    scale_x +
    scale_y

  if (contour %in% c("none", "lines")) {
    plot <-
      plot +
      ggplot2::geom_tile(ggplot2::aes(fill = .data$mean)) +
      ggplot2::scale_fill_gradientn(
        colours = openair::openColours(cols)
      )

    if (contour == "lines") {
      plot <-
        plot +
        ggplot2::geom_contour(
          mapping = ggplot2::aes(z = .data$mean),
          colour = "black",
          bins = contour_bins
        )
    }
  }

  if (contour == "fill") {
    plot <- plot +
      ggplot2::geom_contour_filled(
        mapping = ggplot2::aes(z = .data$mean),
        colour = "black",
        bins = contour_bins
      )

    plot <- plot +
      ggplot2::scale_fill_manual(
        values = openair::openColours(
          cols,
          n = dplyr::n_distinct(ggplot2::ggplot_build(plot)$data[[1]]$fill)
        ),
        aesthetics = "fill"
      )
  }

  if (radial_wd && (var_x == "wd" || var_y == "wd")) {
    plot <-
      plot +
      ggplot2::coord_radial(expand = FALSE, inner.radius = 0.1) +
      ggplot2::theme(
        panel.border = ggplot2::element_blank(),
        axis.line.theta = ggplot2::element_line(linewidth = 0.25)
      ) +
      ggplot2::scale_x_continuous(
        limits = c(0, 360),
        oob = scales::oob_keep,
        breaks = seq(0, 270, 90),
        expand = ggplot2::expansion(),
        labels = c("N", "E", "S", "W")
      )
  } else {
    plot <-
      plot +
      ggplot2::coord_cartesian(default = FALSE, expand = FALSE)
  }

  return(plot)
}


hour_scale <- function(which = c("x", "y")) {
  fun <- if (which == "x") {
    ggplot2::scale_x_continuous
  } else {
    ggplot2::scale_y_continuous
  }

  fun(
    breaks = seq(0, 24, 4),
    limits = c(0, 23),
    oob = scales::oob_keep
  )
}


wd_scale <- function(which = c("x", "y")) {
  if (which == "x") {
    fun <- ggplot2::scale_x_continuous
    sep <- "\n"
  } else {
    fun <- ggplot2::scale_y_continuous
    sep <- " "
  }

  fun(
    breaks = seq(0, 360, 90),
    labels = c(
      paste("0", "(N)", sep = sep),
      paste("90", "(E)", sep = sep),
      paste("180", "(S)", sep = sep),
      paste("270", "(W)", sep = sep),
      paste("360", "(N)", sep = sep)
    ),
    limits = c(0, 360),
    oob = scales::oob_keep
  )
}

# helper for interactive plot
plot_dw_partial_2d.plotly <- function(
  plotdata,
  var_x,
  var_y,
  pollutant,
  contour,
  contour_bins,
  cols,
  show_conf_int,
  radial_wd
) {
  if (show_conf_int || radial_wd) {
    cli::cli_warn(
      "Neither {.arg show_conf_int} nor {.arg radial_wd} are not currently supported by the 'plotly' plotting engine."
    )
  }

  if (contour != "none") {
    # need a square matrix for contour plot
    plotdata <-
      tidyr::complete(
        plotdata,
        .data[[var_x]],
        .data[[var_y]]
      )

    # creating a matrix
    x_vals <- sort(unique(plotdata[[var_x]]))
    y_vals <- sort(unique(plotdata[[var_y]]))
    z_matrix <-
      matrix(
        plotdata$mean,
        nrow = length(y_vals),
        ncol = length(x_vals),
        byrow = FALSE
      )

    plot <-
      plotly::plot_ly(
        x = x_vals,
        y = y_vals,
        z = z_matrix,
        colors = openair::openColours(cols, n = 100),
        colorbar = list(
          title = toupper(pollutant)
        )
      ) |>
      plotly::add_contour(ncontours = contour_bins) |>
      plotly::layout(
        xaxis = list(
          title = var_x
        ),
        yaxis = list(
          title = var_y
        )
      )
  } else {
    plot <- plotly::plot_ly(
      plotdata,
      x = plotdata[[var_x]],
      y = plotdata[[var_y]],
      z = plotdata[["mean"]],
      colors = openair::openColours(cols, n = 100),
      colorbar = list(
        title = toupper(pollutant)
      )
    ) |>
      plotly::add_heatmap() |>
      plotly::layout(
        xaxis = list(
          title = var_x
        ),
        yaxis = list(
          title = var_y
        )
      )
  }

  return(plot)
}
