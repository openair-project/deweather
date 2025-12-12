#' Tune a deweather model
#'
#' This function performs hyperparameter tuning for a gradient boosting model
#' used in deweathering air pollution data. It uses cross-validation to find
#' optimal hyperparameters and returns the best performing model along with
#' performance metrics and visualizations. Parallel processing (e.g., through
#' the `mirai` package) is recommended to speed up tuning - see
#' <https://tune.tidymodels.org/articles/extras/optimizations.html#parallel-processing>.
#'
#' @inheritParams build_dw_model
#'
#' @param
#' tree_depth,trees,learn_rate,mtry,min_n,loss_reduction,sample_size,stop_iter
#' If length 1, these parameters will be fixed. If length `2`, the parameter
#' will be tuned within the range defined between the first and last value. For
#' example, if `tree_depth = c(1, 5)` and `grid_levels = 3`, tree depths of `1`,
#' `3`, and `5` will be tested.
#'
#' @param split_prop The proportion of data to be retained for
#'   modeling/analysis. Passed to the `prop` argument of
#'   [rsample::initial_split()].
#'
#' @param grid_levels An integer for the number of values of each parameter to
#'   use to make the regular grid. Passed to the `levels` argument of
#'   [dials::grid_regular()].
#'
#' @param v_partitions The number of partitions of the data set to use for
#'   v-fold cross-validation. Passed to the `v` argument of
#'   [rsample::vfold_cv()].
#'
#' @details The function performs the following steps:
#'
#' - Removes rows with missing values in the pollutant or predictor variables
#'
#' - Splits data into training and testing sets
#'
#' - Creates a tuning grid for any parameters specified as ranges
#'
#' - Performs grid search with cross-validation to find optimal hyperparameters
#'
#' - Fits a final model using the best hyperparameters
#'
#' - Generates predictions and performance metrics
#'
#'   At least one hyperparameter must be specified as a range (vector of length
#'   2) for tuning to occur. Single values are treated as fixed parameters.
#'
#' @author Jack Davison
#' @export
tune_dw_model <- function(
  data,
  pollutant,
  vars = c("trend", "ws", "wd", "hour", "weekday", "air_temp"),
  tree_depth = 5,
  trees = 200L,
  learn_rate = 0.1,
  mtry = NULL,
  min_n = 10L,
  loss_reduction = 0,
  sample_size = 1L,
  stop_iter = 190L,
  engine = c("xgboost", "lightgbm"),
  split_prop = 3 / 4,
  grid_levels = 5,
  v_partitions = 10
) {
  # check inputs
  engine <- rlang::arg_match(engine, multiple = FALSE)
  vars <- rlang::arg_match(
    vars,
    unique(c(dwVars, names(data))),
    multiple = TRUE
  )

  # if any of the vars given aren't in data, they can be appended by the
  # append_dw_vars function
  if (any(!vars %in% names(data))) {
    vars_to_add <- vars[!vars %in% names(data)]
    data <- append_dw_vars(data, vars = vars_to_add, abbr = TRUE)
  }

  if (engine == "lightgbm") {
    rlang::check_installed(c("lightgbm", "bonsai"))
  }

  # drop all missing values
  data <- data |>
    dplyr::select(dplyr::all_of(c(pollutant, vars))) |>
    dplyr::filter(dplyr::if_all(dplyr::everything(), ~ !is.na(.)))

  # change characters into factors, and ensure factors are unordered
  # (xgboost naming seems to get confused with ordered factors)
  data <- dplyr::mutate(
    data,
    dplyr::across(dplyr::where(is.character), factor),
    dplyr::across(dplyr::where(is.ordered), function(x) {
      factor(x, ordered = FALSE)
    })
  )

  # get testing-training splits
  data_split <- rsample::initial_split(data, prop = split_prop)
  data_train <- rsample::training(data_split)

  # build tuning grid
  grid <- list()

  tree_depth_spec <- tree_depth
  trees_spec <- trees
  learn_rate_spec <- learn_rate
  mtry_spec <- mtry
  min_n_spec <- min_n
  loss_reduction_spec <- loss_reduction
  sample_size_spec <- sample_size
  stop_iter_spec <- stop_iter

  if (length(tree_depth) > 1) {
    grid <- append(grid, list(dials::tree_depth(range = tree_depth)))
    tree_depth_spec <- parsnip::tune()
  }

  if (length(trees) > 1) {
    grid <- append(grid, list(dials::trees(range = trees)))
    trees_spec <- parsnip::tune()
  }

  if (length(learn_rate) > 1) {
    grid <- append(grid, list(dials::learn_rate(range = learn_rate)))
    learn_rate_spec <- parsnip::tune()
  }

  if (length(mtry) > 1) {
    grid <- append(grid, list(dials::mtry(range = mtry)))
    mtry_spec <- parsnip::tune()
  }

  if (length(min_n) > 1) {
    grid <- append(grid, list(dials::min_n(range = min_n)))
    min_n_spec <- parsnip::tune()
  }

  if (length(loss_reduction) > 1) {
    grid <- append(grid, list(dials::loss_reduction(range = loss_reduction)))
    loss_reduction_spec <- parsnip::tune()
  }

  if (length(sample_size) > 1) {
    grid <- append(grid, list(dials::sample_size(range = sample_size)))
    sample_size_spec <- parsnip::tune()
  }

  if (length(stop_iter) > 1) {
    grid <- append(grid, list(dials::stop_iter(range = stop_iter)))
    stop_iter_spec <- parsnip::tune()
  }

  if (length(grid) == 0) {
    cli::cli_abort(
      "At least one parameter (e.g., {.arg tree_depth}) must be given as a range of two values."
    )
  }

  grid <- dials::grid_regular(x = grid, levels = grid_levels)

  # get tuning spec
  tune_spec <-
    parsnip::boost_tree(
      mode = "regression",
      engine = engine,
      tree_depth = !!tree_depth_spec,
      trees = !!trees_spec,
      learn_rate = !!learn_rate_spec,
      mtry = !!mtry_spec,
      min_n = !!min_n_spec,
      loss_reduction = !!loss_reduction_spec,
      sample_size = !!sample_size_spec,
      stop_iter = !!stop_iter_spec
    )

  # get training folds
  folds <- rsample::vfold_cv(data_train, v = v_partitions)

  # build a formula object from poll & vars
  formula <- stats::reformulate(vars, pollutant)

  # create tuning workflow
  wf <-
    workflows::workflow() |>
    workflows::add_model(tune_spec) |>
    workflows::add_formula(formula)

  # get results from grid
  results <- tune::tune_grid(
    wf,
    resamples = folds,
    grid = grid,
    control = tune::control_grid(
      verbose = TRUE,
      allow_par = TRUE,
      parallel_over = "everything"
    )
  )

  # get best models
  five_best_models <- tune::show_best(results, metric = "rmse")

  # get the best overall model
  best_params <- tune::select_best(results, metric = "rmse") |>
    dplyr::select(-".config")

  # finalise workflow
  wf <- tune::finalize_workflow(wf, best_params)

  # one last fit using splits
  final_fit <- tune::last_fit(wf, data_split)

  # final predictions
  final_predictions <-
    tune::collect_predictions(final_fit) |>
    dplyr::select(
      "obs" = !!pollutant,
      "mod" = ".pred"
    ) |>
    dplyr::mutate(
      pollutant = pollutant,
      .before = 0
    )

  # bind to testing dataset for better comparisons
  final_predictions <-
    rsample::testing(final_fit$splits[[1]]) |>
    dplyr::select(-dplyr::any_of(pollutant)) |>
    dplyr::bind_cols(
      final_predictions
    )

  # get model stats
  final_metrics <-
    final_predictions |>
    openair::modStats(type = "pollutant") |>
    dplyr::rename_with(tolower)

  # plot a scatter plot
  axisrange <- range(c(0, final_predictions$obs, final_predictions$mod))
  plot <-
    final_predictions |>
    ggplot2::ggplot(
      ggplot2::aes(x = .data$obs, y = .data$mod)
    ) +
    ggplot2::geom_abline(
      color = "#9E0142FF",
      alpha = 0.5,
      lty = 5,
      slope = 0.5
    ) +
    ggplot2::geom_abline(color = "#9E0142FF", alpha = 0.5, lty = 5, slope = 2) +
    ggplot2::geom_abline(color = "#9E0142FF", lwd = 1.5) +
    ggplot2::geom_point() +
    ggplot2::theme_bw() +
    ggplot2::scale_x_continuous(
      limits = axisrange,
      expand = ggplot2::expansion(c(0, .1))
    ) +
    ggplot2::scale_y_continuous(
      limits = axisrange,
      expand = ggplot2::expansion(c(0, .1))
    ) +
    ggplot2::coord_cartesian(ratio = 1L) +
    ggplot2::labs(
      x = openair::quickText(paste("Observed", pollutant)),
      y = openair::quickText(paste("Modelled", pollutant))
    )

  # return params
  list(
    best_params = as.list(best_params),
    final_fit = list(
      predictions = final_predictions,
      metrics = final_metrics,
      plot = plot
    )
  )
}
