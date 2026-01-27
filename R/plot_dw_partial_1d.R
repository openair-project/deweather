#' Create partial dependence plots for deweather models
#'
#' Generates partial dependence plots to visualize the relationship between
#' predictor variables and model predictions. These plots show how the predicted
#' pollutant concentration changes as a function of one variable while averaging
#' over the effects of all other variables.
#'
#' @param dw A deweather model created with [build_dw_model()].
#'
#' @param vars Character. The name of the variable(s) to plot. Must be one of
#'   the variables used in the model. If `NULL`, all variables will be plotted
#'   in order of importance.
#'
#' @param intervals The number of points for the partial dependence profile.
#'
#' @param group Optional grouping variable to show separate profiles for
#'   different levels of another predictor. Must be one of the variables used in
#'   the model. Default is `NULL` (no grouping).
#'
#' @param group_intervals The number of bins when the `group` variable is
#'   numeric.
#'
#' @param show_conf_int Should the bootstrapped 95% confidence interval be
#'   shown? In [plot_dw_partial_1d()] these are shown using transparent ribbons
#'   (for numeric variables) and rectangles (for categorical variables).
#'
#' @param show_rug Should a 'rug' (ticks along the x-axis) be shown which
#'   identifies the exact intervals for each parameter?
#'
#' @param n The number of observations to use for calculating the partial
#'   dependence profile. If `NULL` (default), uses `prop` to determine the
#'   sample size.
#'
#' @param prop The proportion of input data to use for calculating the partial
#'   dependence profile, between 0 and 1. Default is `0.01` (1% of input data).
#'   Ignored if `n` is specified.
#'
#' @param ylim The limits of the y-axis. Passed to the `ylim` argument of
#'   [ggplot2::coord_cartesian()] (or `rlim` of [ggplot2::coord_radial()] if
#'   `radial_wd` is `TRUE`). The default, `NULL`, allows each partial dependence
#'   panel to have its own y-axis scale.
#'
#' @param cols Colours to use for plotting. See [openair::openColours()].
#'
#' @param radial_wd Should the `"wd"` (wind direction) variable be plotted on a
#'   radial axis? This can enhance interpretability, but makes it inconsistent
#'   with other variables which are plotted on cartesian coordinates. Defaults
#'   to `TRUE`.
#'
#' @param ncol,nrow When more than one `vars` is defined, `ncol` and `nrow`
#'   define the dimensions of the grid to create. Setting both to be `NULL`
#'   creates a roughly square grid.
#'
#' @param plot When `FALSE`, return a list of plot data instead of a plot.
#'
#' @param .progress Show a progress bar? Defaults to `TRUE` in interactive
#'   sessions.
#'
#' @return A `ggplot2` object showing the partial dependence plot. If multiple
#'   `vars` are specified, a `patchwork` assembly of plots will be returned. If
#'   `plot = FALSE`, a named list of plot data will be returned instead.
#'
#' @param ... Not currently used.
#'
#' @param .plot_engine The plotting engine to use. One of `"ggplot2"`, which
#'   returns a static plot, or `"plotly"`, which returns a dynamic HTML plot.
#'
#' @export
plot_dw_partial_1d <- function(
  dw,
  vars = NULL,
  intervals = 40L,
  group = NULL,
  group_intervals = 3L,
  show_conf_int = TRUE,
  show_rug = TRUE,
  n = NULL,
  prop = 0.01,
  cols = "tol",
  ylim = NULL,
  radial_wd = TRUE,
  ncol = NULL,
  nrow = NULL,
  plot = TRUE,
  ...,
  .progress = rlang::is_interactive(),
  .plot_engine = c("ggplot2", "plotly")
) {
  check_deweather(dw)
  rlang::check_dots_empty()
  .plot_engine <- check_plot_engine(.plot_engine, .plot_engine)

  model <- get_dw_model(dw)
  input_data <- get_dw_input_data(dw)
  pollutant <- get_dw_pollutant(dw)
  importance <- get_dw_importance(dw, aggregate_factors = TRUE)

  # check inputs against model variables
  model_vars <- get_dw_vars(dw)
  vars <- vars %||% rev(levels(importance$var))
  vars <- rlang::arg_match(vars, model_vars, multiple = TRUE)
  if (!is.null(group)) {
    rlang::arg_match(group, model_vars, multiple = FALSE)
  }

  # ensure `group` is not trend
  if (!is.null(group)) {
    if (group == "trend") {
      cli::cli_abort("{.arg group} cannot be 'trend'.")
    }
  }
  # check other inputs
  if (!is.null(prop) && (prop > 1 || prop < 0)) {
    cli::cli_abort("{.arg prop} must be between `0` and `1`.")
  }

  # cut a numeric group
  if (!is.null(group) && is.numeric(input_data[[group]])) {
    group_breaks <- stats::quantile(
      input_data[[group]],
      probs = seq(0, 1, length.out = group_intervals + 1L),
      na.rm = TRUE
    )

    input_data$group_var <-
      cut(
        input_data[[group]],
        breaks = group_breaks,
        include.lowest = TRUE
      )
  } else if (!is.null(group)) {
    input_data$group_var <- input_data[[group]]
  } else {
    input_data$group_var <- "(all)"
    group <- "NULL"
  }

  # rows to use in data
  n_rows <- n %||% round(prop * nrow(input_data))
  obs_df <- dplyr::slice_sample(
    input_data,
    n = n_rows,
    replace = FALSE,
    by = "group_var"
  )

  # calculate PD profiles
  pd_data <- list()
  for (i in vars) {
    # get 1d CP
    cp <- cp_profiles(
      dw = dw,
      obs = obs_df,
      var_x = i,
      var_y = NULL,
      progress = if (.progress) i else FALSE
    )

    if (i == group && is.numeric(cp[[i]])) {
      cp$`__dummy__` <- cut(
        cp[[i]],
        breaks = group_breaks,
        include.lowest = TRUE
      )
      cp <- dplyr::filter(cp, .data$group_var == .data[["__dummy__"]])
      cp$`__dummy__` <- NULL
    }

    if (i == group && is.factor(cp[[i]])) {
      cp <- dplyr::filter(cp, .data$group_var == .data[[i]])
    }

    # calculate mean
    pd <-
      dplyr::reframe(
        cp,
        openair::bootMeanDF(.data[[pollutant]], B = 100),
        .by = dplyr::all_of(c(i, "group_var"))
      )

    pd_data <- append(pd_data, stats::setNames(list(pd), i))
  }

  # ensure plot data is in order of variables
  pd_data <- pd_data[vars]

  # if not plotting, just return list of data
  if (!plot) {
    return(pd_data)
  }

  if (.plot_engine == "ggplot2") {
    plots <- plot_dw_partial_1d.ggplot2(
      dw,
      pd_data,
      importance,
      group,
      pollutant,
      cols,
      ylim,
      show_conf_int,
      show_rug,
      radial_wd,
      vars,
      ncol,
      nrow
    )
  }

  if (.plot_engine == "plotly") {
    plots <- plot_dw_partial_1d.plotly(
      dw,
      pd_data,
      importance,
      group,
      pollutant,
      cols,
      ylim,
      show_conf_int,
      show_rug,
      radial_wd,
      vars,
      ncol,
      nrow
    )
  }

  return(plots)
}

#' Helper for static plots
#' @noRd
plot_dw_partial_1d.ggplot2 <- function(
  dw,
  pd_data,
  importance,
  group,
  pollutant,
  cols,
  ylim,
  show_conf_int,
  show_rug,
  radial_wd,
  vars,
  ncol,
  nrow
) {
  # create plots
  plots <-
    purrr::map(
      vars,
      \(x) {
        plot_single_pd.ggplot2(
          dw,
          pd_data,
          importance,
          x,
          group,
          pollutant,
          cols,
          ylim,
          show_conf_int,
          show_rug,
          radial_wd
        )
      }
    ) |>
    stats::setNames(vars)

  # if more than one plot, return a patchwork
  if (length(plots) > 1) {
    # strip away most legends
    for (i in 1:length(plots)) {
      if (i != 1) {
        plots[[i]] <- plots[[i]] + ggplot2::theme(legend.position = "none")
      }
    }

    # combine into patchwork
    plots <-
      patchwork::wrap_plots(plots) +
      patchwork::plot_layout(
        widths = 1,
        heights = 1,
        guides = "collect",
        ncol = ncol,
        nrow = nrow
      )
  } else {
    plots <- plots[[1]]
  }

  return(plots)
}

#' Helper for static plots - single panel
#' @noRd
plot_single_pd.ggplot2 <- function(
  dw,
  pd_data,
  importance,
  var,
  group,
  pollutant,
  cols,
  ylim,
  show_conf_int,
  show_rug,
  radial_wd
) {
  df <- pd_data[[var]]

  # find colours
  colours <- openair::openColours(
    scheme = cols,
    n = dplyr::n_distinct(df$group_var)
  )

  # if the variable is "trend", convert it to a datetime and drop the far
  # reaches of it
  if (var == "trend") {
    df <-
      df |>
      dplyr::tibble() |>
      dplyr::filter(!.data$trend %in% range(.data$trend)) |>
      dplyr::mutate(
        trend = as.POSIXct(.data$trend, tz = dw$tz)
      )
  }

  # create plot
  plot <-
    df |>
    ggplot2::ggplot(
      ggplot2::aes(
        x = .data[[var]],
        y = .data$mean,
        ymax = .data$max,
        ymin = .data$min
      )
    )

  # geometries - different if a variable is numeric vs categorical
  if (!is.numeric(df[[var]]) && !lubridate::is.POSIXct(df[[var]])) {
    if (show_conf_int) {
      plot <-
        plot +
        ggplot2::geom_crossbar(
          ggplot2::aes(fill = .data$group_var),
          alpha = 0.3,
          color = NA,
          show.legend = FALSE
        )
    }
    plot <-
      plot +
      ggplot2::geom_crossbar(
        ggplot2::aes(
          ymin = .data$mean,
          ymax = .data$mean,
          color = .data$group_var
        ),
        key_glyph = ggplot2::draw_key_path
      )
  } else {
    if (show_conf_int) {
      plot <-
        plot +
        ggplot2::geom_ribbon(
          ggplot2::aes(
            fill = factor(.data$group_var)
          ),
          show.legend = FALSE,
          alpha = 0.3
        )
    }
    plot <-
      plot +
      ggplot2::geom_line(
        ggplot2::aes(
          color = factor(.data$group_var)
        )
      )
  }

  # add themes
  plot <-
    plot +
    theme_deweather() +
    ggplot2::scale_y_continuous(
      breaks = scales::breaks_pretty(6)
    ) +
    ggplot2::scale_color_manual(
      values = colours,
      aesthetics = c("fill", "color"),
      name = openair::quickText(group)
    ) +
    ggplot2::labs(
      y = openair::quickText(pollutant),
      x = openair::quickText(var)
    )

  # wind direction needs special handling
  if (var == "wd") {
    # if radial, needs its own scale and coord
    if (radial_wd) {
      plot <-
        plot +
        ggplot2::scale_x_continuous(
          breaks = seq(0, 270, 90),
          labels = c(
            "N",
            "E",
            "S",
            "W"
          ),
          limits = c(0, 360),
          expand = ggplot2::expansion()
        ) +
        ggplot2::coord_radial(rlim = ylim) +
        ggplot2::theme(
          panel.border = ggplot2::element_blank(),
          axis.line.theta = ggplot2::element_line(linewidth = 0.25),
          panel.grid.major.x = ggplot2::element_line()
        )
    } else {
      # treat as cartesian
      plot <-
        plot +
        ggplot2::scale_x_continuous(
          breaks = seq(0, 360, 90),
          labels = c(
            "0\n(N)",
            "90\n(E)",
            "180\n(S)",
            "270\n(W)",
            "360\n(N)"
          ),
          limits = c(0, 360)
        ) +
        ggplot2::coord_cartesian(
          ylim = ylim
        )

      if (show_rug) {
        plot <-
          plot +
          ggplot2::geom_rug(
            data = dplyr::distinct(df, .data[[var]]),
            mapping = ggplot2::aes(y = NULL, x = .data[[var]]),
            color = "black",
            inherit.aes = FALSE
          )
      }
    }
  } else {
    # default cartesian handling
    plot <-
      plot +
      ggplot2::coord_cartesian(
        ylim = ylim
      )

    if (
      show_rug && (is.numeric(df[[var]]) || lubridate::is.POSIXct(df[[var]]))
    ) {
      plot <- plot +
        ggplot2::geom_rug(
          data = dplyr::distinct(df, .data[[var]]),
          mapping = ggplot2::aes(y = NULL, x = .data[[var]]),
          color = "black",
          inherit.aes = FALSE
        )
    }
  }

  if (var == "hour") {
    plot <-
      plot +
      ggplot2::scale_x_continuous(
        breaks = seq(0, 24, 4),
        limits = c(0, 23)
      )
  }

  if (length(colours) == 1L) {
    plot <- plot +
      ggplot2::guides(
        color = ggplot2::guide_none(),
        fill = ggplot2::guide_none()
      )
  }

  # add title - if boost tree, add importance gain %, else just variable name
  scale_fun <- if (dw$engine$method == "boost_tree") {
    gain <- scales::label_percent(0.1)(importance$importance[
      importance$var == var
    ])
    plot <- plot +
      ggplot2::labs(
        title = openair::quickText(paste0(var, " (", gain, ")"))
      )
  } else {
    plot <- plot +
      ggplot2::labs(
        title = openair::quickText(var)
      )
  }

  return(plot)
}

#' Helper for static plots
#' @noRd
plot_dw_partial_1d.plotly <- function(
  dw,
  pd_data,
  importance,
  group,
  pollutant,
  cols,
  ylim,
  show_conf_int,
  show_rug,
  radial_wd,
  vars,
  ncol,
  nrow
) {
  # create plots
  plots <-
    purrr::map(
      vars,
      \(x) {
        plot_single_pd.plotly(
          dw,
          pd_data,
          importance,
          x,
          group,
          pollutant,
          cols,
          ylim,
          show_conf_int,
          show_rug,
          radial_wd,
          showlegend = x == vars[1]
        )
      }
    ) |>
    stats::setNames(vars)

  # if more than one plot, return a patchwork
  if (length(plots) > 1) {
    # strip away most legends
    for (i in 1:length(plots)) {
      if (i != 1) {
        plots[[i]] <- plots[[i]]
      }
    }

    n_plots <- length(plots)

    if (is.null(nrow)) {
      if (!is.null(ncol)) {
        nrow <- ceiling(n_plots / ncol)
      } else {
        nrow <- floor(sqrt(n_plots))
      }
    }

    plots <- plotly::subplot(
      plots,
      nrows = nrow,
      titleX = TRUE,
      titleY = TRUE,
      margin = c(0.04, 0.04, 0.10, 0.10)
    )
  } else {
    plots <- plots[[1]]
  }

  return(plots)
}

#' Helper for static plots - single panel
#' @noRd
plot_single_pd.plotly <- function(
  dw,
  pd_data,
  importance,
  var,
  group,
  pollutant,
  cols,
  ylim,
  show_conf_int,
  show_rug,
  radial_wd,
  ncol,
  nrow,
  showlegend
) {
  df <- pd_data[[var]]

  # find colours
  colours <- openair::openColours(
    scheme = cols,
    n = dplyr::n_distinct(df$group_var)
  )

  # if the variable is "trend", convert it to a datetime and drop the far
  # reaches of it
  if (var == "trend") {
    df <-
      df |>
      dplyr::tibble() |>
      dplyr::filter(!.data$trend %in% range(.data$trend)) |>
      dplyr::mutate(
        trend = as.POSIXct(.data$trend, tz = dw$tz)
      )
  }

  if (is.numeric(df[[var]]) || lubridate::is.POSIXct(df[[var]])) {
    plot <- plotly::plot_ly(
      df,
      x = df[[var]],
      y = df$mean,
      ymin = df$min,
      ymax = df$max,
      color = df$group_var,
      colors = openair::openColours(cols, dplyr::n_distinct(df$group_var)),
      showlegend = dplyr::n_distinct(df$group_var) > 1L,
      legendgroup = df$group_var
    )

    if (show_conf_int) {
      plot <- plot |>
        plotly::add_ribbons(line = list(width = 0), showlegend = FALSE)
    }

    plot <- plot |> plotly::add_lines(showlegend = showlegend)
  } else {
    error_y <- NULL
    if (show_conf_int) {
      error_y <- list(
        symmetric = FALSE,
        array = df$max - df$mean,
        arrayminus = df$mean - df$min
      )
    }
    plot <-
      plotly::plot_ly(
        df,
        x = df[[var]],
        y = df$mean,
        error_y = error_y,
        color = df$group_var,
        colors = openair::openColours(cols, dplyr::n_distinct(df$group_var)),
        showlegend = showlegend && dplyr::n_distinct(df$group_var) > 1L,
        legendgroup = df$group_var
      ) |>
      plotly::add_markers(
        marker = list(
          size = 10
        )
      )
  }

  # add title - if boost tree, add importance gain %, else just variable name
  title <- var
  if (dw$engine$method == "boost_tree") {
    gain <- scales::label_percent(0.1)(importance$importance[
      importance$var == var
    ])
    title <- paste0(var, " (", gain, ")")
  }

  plot <- plot |>
    plotly::layout(
      yaxis = list(
        title = toupper(pollutant),
        range = ylim
      ),
      xaxis = list(
        title = title
      ),
      hovermode = "x unified",
      legend = list(
        title = list(
          text = group
        )
      )
    )

  return(plot)
}
