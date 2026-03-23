#' Plot SHAP importance for Deweather models
#'
#' This function computes SHAP values for a Deweather model and plots the
#' importance of specified features. SHAP values show the contribution of each
#' feature to the model's predictions, allowing for a better understanding of
#' which features are most influential in the model. Wider ranges of SHAP values
#' indicate greater importance of the feature in the model's predictions. The
#' colour represents the normalised feature value, with darker colours
#' indicating higher values of the feature. This allows for the identification
#' of patterns in how feature values relate to their importance in the model's
#' predictions.
#'
#' @inheritParams shared_deweather_params
#' @inheritSection shared_deweather_params Plotting Engines
#'
#' @param vars Character. The name of the variable(s) to plot. Must be one of
#'   the variables used in the model. If `NULL`, all variables will be plotted
#'   in order of importance.
#'
#' @param nsim The number of Monte Carlo repetitions to use for estimating each
#'   Shapley value, for engines which require `fastshap::explain()` (currently
#'   `"ranger"`). Ignored for other engines.
#'
#' @param n The number of observations to use for calculating SHAP values. If
#'   `NULL` (default), uses `prop` to determine the sample size.
#'
#' @param prop The proportion of input data to use for calculating the partial
#'   dependence profile, between 0 and 1. Default is `0.05` (5% of input data).
#'   Ignored if `n` is specified.
#'
#' @author Jack Davison
#'
#' @returns A `ggplot2` or `plotly` object showing the SHAP importance of the
#'   specified features. If `.plot` is `FALSE`, returns a list containing the
#'   data used for plotting and a `shapviz` object.
#'
#' @examples
#' \dontrun{
#' dw <- build_dw_model(aqroadside, "no2")
#' plot_dw_shap_importance(dw)
#' }
plot_dw_shap_importance <- function(
  dw,
  vars = NULL,
  n = NULL,
  prop = 0.05,
  nsim = 50,
  cols = "turbo",
  ...,
  .plot = TRUE,
  .plot_engine = NULL
) {
  # extract model features
  check_deweather(dw, "Deweather")
  .plot_engine <- check_plot_engine(.plot_engine)
  input_data <- get_dw_input_data(dw)
  pollutant <- get_dw_pollutant(dw)
  engine <- get_dw_engine(dw)
  vars <- vars %||% get_dw_vars(dw)

  # xgboost turns factors into separate variables
  for (i in vars) {
    if (is.factor(input_data[[i]])) {
      vars <- c(vars, paste0(i, levels(input_data[[i]])))
    }
  }

  # check packages
  pkgs_needed <- c("shapviz")
  if (engine == "ranger") {
    pkgs_needed <- c(pkgs_needed, "fastshap")
  }
  if (.plot_engine == "ggplot2") {
    pkgs_needed <- c(pkgs_needed, "ggbeeswarm")
  }
  rlang::check_installed(pkgs_needed)

  # sample data
  n <- n %||% round(prop * nrow(input_data))
  input_data_sample <- input_data |>
    dplyr::select(!dplyr::all_of(pollutant)) |>
    dplyr::slice_sample(n = n)

  # get shapviz object
  if (engine == "xgboost") {
    sv <- get_sv.xgboost(dw, input_data_sample)
  } else if (engine == "lightgbm") {
    sv <- get_sv.lightgbm(dw, input_data_sample)
  } else if (engine == "ranger") {
    sv <- get_sv.ranger(dw, input_data_sample, nsim)
  } else {
    cli::cli_abort(
      "The '{engine}' engine is not supported by {.fun deweather::plot_dw_shap_importance}."
    )
  }

  # restructure for plotting
  rn_to_column <- function(data, column) {
    data[[column]] <- rownames(data)
    data
  }

  shap_df <- shapviz::get_shap_values(sv) |>
    as.data.frame() |>
    rn_to_column("obs") |>
    tidyr::pivot_longer(-"obs", names_to = "feature", values_to = "shap_value")

  feat_df <- shapviz::get_feature_values(sv) |>
    as.data.frame() |>
    dplyr::mutate(dplyr::across(dplyr::everything(), as.numeric)) |>
    rn_to_column("obs") |>
    tidyr::pivot_longer(
      -"obs",
      names_to = "feature",
      values_to = "feature_value"
    )

  plot_df <-
    dplyr::left_join(shap_df, feat_df, by = c("obs", "feature")) |>
    dplyr::filter(
      .data$feature %in% vars
    ) |>
    dplyr::mutate(
      avg_shap_value = mean(abs(.data$shap_value)),
      .by = "feature",
      .after = "shap_value"
    ) |>
    dplyr::mutate(
      feature_value_norm = scales::rescale(.data$feature_value, to = c(0, 1)),
      .by = "feature"
    )

  # get mean absolute shap value for importance
  avg_shap_df <-
    plot_df |>
    dplyr::distinct(.data$feature, .data$avg_shap_value) |>
    dplyr::arrange(dplyr::desc(.data$avg_shap_value))

  plot_df$feature <- factor(plot_df$feature, rev(avg_shap_df$feature))
  avg_shap_df$feature <- factor(avg_shap_df$feature, rev(avg_shap_df$feature))

  # need nice labels for plotly graphics
  plot_df <-
    split(plot_df, plot_df$feature) |>
    purrr::imap(
      \(df, i) {
        if (i == "trend") {
          df$feature_value_str <- as.POSIXct(df$feature_value, tz = dw$tz) |>
            as.character()
        } else if (is.factor(input_data[[i]])) {
          factor_levels <- levels(input_data[[i]])
          df$feature_value_str <- dplyr::recode_values(
            df$feature_value,
            from = seq_along(factor_levels),
            to = factor_levels
          )
        } else {
          df$feature_value_str <- prettyNum(df$feature_value)
        }

        return(df)
      }
    ) |>
    dplyr::bind_rows()

  if (!.plot) {
    return(
      list(
        data = plot_df,
        shapviz = sv
      )
    )
  }

  if (.plot_engine == "ggplot2") {
    plot <- plot_dw_shap_importance.ggplot2(plot_df, avg_shap_df, cols)
  }

  if (.plot_engine == "plotly") {
    plot <- plot_dw_shap_importance.plotly(plot_df, avg_shap_df, cols)
  }

  return(plot)
}

# plotting functions for different engines

plot_dw_shap_importance.ggplot2 <- function(plot_df, avg_shap_df, cols) {
  plot_df |>
    ggplot2::ggplot(ggplot2::aes(
      y = .data[["feature"]],
      x = .data[["shap_value"]],
      color = .data[["feature_value_norm"]]
    )) +
    ggplot2::geom_vline(xintercept = 0, lty = 2) +
    ggbeeswarm::geom_quasirandom(orientation = "y") +
    theme_deweather(dir = "x") +
    ggplot2::theme(
      legend.position = "bottom",
      legend.title.position = "top",
      legend.title = ggplot2::element_text(hjust = 0.5)
    ) +
    ggplot2::scale_y_discrete(
      label = \(x) sapply(x, openair::quickText),
      sec.axis = ggplot2::dup_axis(
        name = "Mean Absolute SHAP",
        labels = prettyNum(signif(rev(avg_shap_df$avg_shap_value), 3))
      )
    ) +
    ggplot2::scale_color_gradientn(
      colours = openair::openColours(cols),
      breaks = c(0, 1),
      labels = c("Low", "High")
    ) +
    ggplot2::labs(
      y = "Feature",
      x = "SHAP value",
      color = "Feature Value"
    )
}

plot_dw_shap_importance.plotly <- function(plot_df, avg_shap_df, cols) {
  feature_order <- rev(levels(plot_df$feature))

  plot_df |>
    dplyr::mutate(feature = as.character(.data$feature)) |>
    plotly::plot_ly(
      y = ~ toupper(feature),
      x = ~shap_value,
      text = ~feature_value_str,
      color = ~feature_value_norm,
      colors = openair::openColours(cols),
      hovertemplate = paste(
        "<b>%{y}</b><br>",
        "SHAP value: %{x}<br>",
        "Feature value: %{text}<extra></extra>"
      )
    ) |>
    plotly::add_markers() |>
    plotly::layout(
      yaxis = list(
        categoryorder = "array",
        categoryarray = rev(toupper(feature_order)),
        title = "Feature",
        tickmode = "array",
        tickvals = toupper(avg_shap_df$feature),
        ticktext = paste0(
          "<b>",
          toupper(avg_shap_df$feature),
          "</b><br>(Mean Abs SHAP: ",
          signif(avg_shap_df$avg_shap_value, 3),
          ")"
        )
      ),
      xaxis = list(title = "SHAP value")
    ) |>
    plotly::colorbar(
      title = "Normalised<br>Feature<br>Value"
    )
}

# get shapviz object for different engines

get_sv.xgboost <- function(dw, data) {
  shapviz::shapviz(
    get_dw_model(dw)$fit,
    X_pred = stats::model.matrix(~ . - 1, data = data),
    X = stats::model.matrix(~ . - 1, data = data) |> as.data.frame()
  )
}

get_sv.lightgbm <- function(dw, data) {
  shapviz::shapviz(
    get_dw_model(dw)$fit,
    X_pred = data.matrix(data),
    X = data
  )
}

get_sv.ranger <- function(dw, data, nsim) {
  shap <-
    fastshap::explain(
      object = get_dw_model(dw)$fit,
      X = data,
      nsim = nsim,
      pred_wrapper = \(object, newdata) {
        stats::predict(object, data = newdata)$predictions
      },
      shap_only = FALSE
    )

  shapviz::shapviz(shap)
}
