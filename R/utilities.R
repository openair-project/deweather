#' make CP profiles from a model
#' @param dw A deweather model
#' @param obs A dataframe of rows to use for the observed values
#' @param var_x,var_y variables. y can be NULL - this creates a 1D CP
#' @param intervals as parent fun
#' @noRd
cp_profiles <- function(
  dw,
  obs,
  var_x,
  var_y = NULL,
  intervals = 101,
  progress = TRUE
) {
  is_2pd <- !is.null(var_y)
  data <- get_dw_input_data(dw)

  # Grids (shared across all obs)
  x_grid <- NULL
  y_grid <- NULL
  if (is_2pd) {
    if (is.numeric(data[[var_x]]) || lubridate::is.POSIXct(data[[var_x]])) {
      xrange <- range(data[[var_x]])
      if (var_x == "wd") {
        xrange <- c(0, 360)
      }
      if (var_x == "hour") {
        xrange <- c(0, 23)
      }

      x_grid <- seq(
        xrange[1],
        xrange[2],
        length.out = intervals
      )
    } else {
      x_grid <- factor(unique(data[[var_x]]), levels = levels(data[[var_x]]))
    }

    if (is.numeric(data[[var_y]]) || lubridate::is.POSIXct(data[[var_y]])) {
      yrange <- range(data[[var_y]])
      if (var_y == "wd") {
        yrange <- c(0, 360)
      }
      if (var_y == "hour") {
        yrange <- c(0, 23)
      }

      y_grid <- seq(
        yrange[1],
        yrange[2],
        length.out = intervals
      )
    } else {
      y_grid <- factor(unique(data[[var_y]]), levels = levels(data[[var_y]]))
    }
  } else {
    if (is.numeric(data[[var_x]]) || lubridate::is.POSIXct(data[[var_x]])) {
      probs <- seq(0, 1, length.out = intervals)
      x_grid <- unname(stats::quantile(data[[var_x]], probs, na.rm = TRUE))
    } else {
      x_grid <- factor(unique(data[[var_x]]), levels = levels(data[[var_x]]))
    }
  }

  # need pollutant
  pollutant <- get_dw_pollutant(dw)

  # For each obs row, build the grid with "other vars" fixed, then predict
  out <-
    purrr::map(
      .x = seq_len(nrow(obs)),
      .f = purrr::in_parallel(
        function(i) {
          obs_i <- obs[i, , drop = FALSE]

          if (is.null(var_y)) {
            new_data <- tidyr::crossing(
              x_new = x_grid,
              dplyr::select(obs_i, -dplyr::all_of(c(var_x, pollutant)))
            )
            names(new_data)[names(new_data) == "x_new"] <- var_x
          } else {
            new_data <- tidyr::crossing(
              x_new = x_grid,
              y_new = y_grid,
              dplyr::select(
                obs_i,
                -dplyr::all_of(c(var_x, var_y, pollutant))
              )
            )
            names(new_data)[names(new_data) == "x_new"] <- var_x
            names(new_data)[names(new_data) == "y_new"] <- var_y
          }

          # out <- predict_dw(dw, new_data, column_bind = TRUE)

          # Track which obs produced these rows
          dplyr::mutate(new_data, .obs_id = i, .before = 1)
        },
        pollutant = pollutant,
        obs = obs,
        var_x = var_x,
        var_y = var_y,
        x_grid = x_grid,
        y_grid = y_grid
      ),
      .progress = progress
    ) |>
    dplyr::bind_rows()

  # predict and return
  predict_dw(dw, out, column_bind = TRUE)
}

#' Check if plotting engines are available
#' @noRd
check_plot_engine <- function(.plot_engine, opts = c("ggplot2", "plotly")) {
  .plot_engine <- .plot_engine %||%
    getOption("deweather.plot_engine") %||%
    "ggplot2"
  x <- rlang::arg_match(.plot_engine, opts, multiple = FALSE)
  if (x == "ggplot2") {
    rlang::check_installed(
      c("ggplot2", "scales", "patchwork"),
      version = c("4.0.0", NA, NA)
    )
  }
  if (x == "plotly") {
    rlang::check_installed(c("plotly", "scales"))
  }
  return(x)
}

#' Check if the deps are installed for a specific engine
#' @noRd
check_engine_installed <- function(engine) {
  if (engine == "xgboost") {
    rlang::check_installed(c("xgboost"))
  }
  if (engine == "lightgbm") {
    rlang::check_installed(c("lightgbm", "bonsai"))
  }
  if (engine == "ranger") {
    rlang::check_installed(c("ranger"))
  }
}


#' Get the engine method
#' @noRd
define_engine_method <- function(engine) {
  x <- dplyr::recode_values(
    engine,
    c("xgboost", "lightgbm") ~ "boost_tree",
    c("ranger") ~ "rand_forest",
    default = "unknown"
  )
  if (x == "unknown") {
    cli::cli_abort(
      "No engine method has been defined for the '{engine}' engine.",
      .internal = TRUE
    )
  }
  return(x)
}

#' A nice modern ggplot2 theme
#' @noRd
theme_deweather <- function(dir = c("y", "x"), ...) {
  dir <- rlang::arg_match(dir)

  # Only apply custom theme if the user hasn't set a custom theme
  if (is_default_theme()) {
    theme <-
      ggplot2::theme_minimal() +
      ggplot2::theme(
        panel.grid.minor = ggplot2::element_blank(),
        strip.background = ggplot2::element_blank(),
        strip.text.x.top = ggplot2::element_text(hjust = 0)
      )

    if (dir == "x") {
      theme <- theme +
        ggplot2::theme(
          panel.grid.major.y = ggplot2::element_blank(),
          axis.line.y.left = ggplot2::element_line()
        )
    } else {
      theme <- theme +
        ggplot2::theme(
          panel.grid.major.x = ggplot2::element_blank(),
          axis.line.x.bottom = ggplot2::element_line()
        )
    }
  } else {
    theme <- ggplot2::theme()
  }

  theme <- theme + ggplot2::theme(...)

  return(theme)
}

#' Check if the user has set a theme
#' @noRd
is_default_theme <- function() {
  identical(ggplot2::theme_get(), ggplot2::theme_gray())
}
