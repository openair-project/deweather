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

  # For each obs row, build the grid with "other vars" fixed, then predict
  purrr::map(
    .x = seq_len(nrow(obs)),
    .f = function(i) {
      obs_i <- obs[i, , drop = FALSE]

      if (is.null(var_y)) {
        new_data <- tidyr::crossing(
          x_new = x_grid,
          dplyr::select(obs_i, -dplyr::all_of(c(var_x, get_dw_pollutant(dw))))
        )
        names(new_data)[names(new_data) == "x_new"] <- var_x
      } else {
        new_data <- tidyr::crossing(
          x_new = x_grid,
          y_new = y_grid,
          dplyr::select(
            obs_i,
            -dplyr::all_of(c(var_x, var_y, get_dw_pollutant(dw)))
          )
        )
        names(new_data)[names(new_data) == "x_new"] <- var_x
        names(new_data)[names(new_data) == "y_new"] <- var_y
      }

      out <- predict_dw(dw, new_data, column_bind = TRUE)

      # Track which obs produced these rows
      dplyr::mutate(out, .obs_id = i, .before = 1)
    },
    .progress = progress
  ) |>
    dplyr::bind_rows()
}
