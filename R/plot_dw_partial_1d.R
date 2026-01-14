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
#' @param n The number of observations to use for calculating the partial
#'   dependence profile. If `NULL` (default), uses `prop` to determine the
#'   sample size.
#'
#' @param prop The proportion of input data to use for calculating the partial
#'   dependence profile, between 0 and 1. Default is `0.1` (10% of data).
#'   Ignored if `n` is specified.
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
#' @param progress Show a progress bar? Defaults to `TRUE` in interactive
#'   sessions.
#'
#' @return A `ggplot2` object showing the partial dependence plot. If multiple
#'   `vars` are specified, a `patchwork` assembly of plots will be returned. If
#'   `plot = FALSE`, a named list of plot data will be returned instead.
#'
#' @export
plot_dw_partial_1d <- function(
  dw,
  vars = NULL,
  intervals = 40L,
  group = NULL,
  group_intervals = 3L,
  show_conf_int = TRUE,
  n = NULL,
  prop = 0.01,
  cols = "Set1",
  radial_wd = TRUE,
  ncol = NULL,
  nrow = NULL,
  plot = TRUE,
  progress = rlang::is_interactive()
) {
  check_deweather(dw)

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
      progress = if (progress) i else FALSE
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

    # calculate mean
    pd <-
      dplyr::reframe(
        cp,
        openair::bootMeanDF(.data[[pollutant]], B = 100),
        .by = dplyr::all_of(c(i, "group_var"))
      )

    pd_data <- append(pd_data, stats::setNames(list(pd), i))
  }

  # function that plots one variable
  plot_single_pd <- function(var) {
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
            key_glyph = ggplot2::draw_key_polygon
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
      ggplot2::theme_bw() +
      ggplot2::theme(
        plot.title = ggplot2::element_text(face = "bold")
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

    # make wind direction radial
    if (var == "wd") {
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
          ggplot2::coord_radial(r.axis.inside = 315) +
          ggplot2::theme(
            panel.border = ggplot2::element_blank(),
            axis.line.theta = ggplot2::element_line(linewidth = 0.25)
          )

        plot <- patchwork::free(plot)
      } else {
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

    # add title
    gain <- scales::label_percent(0.1)(importance$importance[
      importance$var == var
    ])
    plot <- plot +
      ggplot2::labs(
        title = paste0(var, " (", gain, ")")
      )

    return(plot)
  }

  # ensure plot data is in order of variables
  pd_data <- pd_data[vars]

  if (!plot) {
    return(pd_data)
  }

  plots <-
    purrr::map(
      vars,
      plot_single_pd,
      .progress = progress
    ) |>
    stats::setNames(vars)

  if (length(plots) > 1) {
    for (i in 1:length(plots)) {
      if (i != 1) {
        plots[[i]] <- plots[[i]] + ggplot2::theme(legend.position = "none")
      }
    }

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
