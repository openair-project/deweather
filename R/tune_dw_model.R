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
#' `3`, and `5` will be tested. See [build_dw_model()] for specific parameter
#' definitions.
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
#' @param .progress Log progress in the console? Passed to the `verbose` argument
#'   of [tune::control_grid()]. Note that logging does not occur when parallel
#'   processing is used.
#'
#' @details The function performs the following steps:
#'
#'   - Removes rows with missing values in the pollutant or predictor variables
#'
#'   - Splits data into training and testing sets
#'
#'   - Creates a tuning grid for any parameters specified as ranges
#'
#'   - Performs grid search with cross-validation to find optimal hyperparameters
#'
#'   - Fits a final model using the best hyperparameters
#'
#'   - Generates predictions and performance metrics
#'
#'   At least one hyperparameter must be specified as a range (vector of length
#'   2) for tuning to occur. Single values are treated as fixed parameters.
#'
#' @inheritSection build_dw_model Modelling Approaches and Parameters
#'
#' @family Model Tuning Functions
#' @author Jack Davison
#' @export
tune_dw_model <- function(
  data,
  pollutant,
  vars = c("trend", "ws", "wd", "hour", "weekday", "air_temp"),
  tree_depth = 5,
  trees = 50L,
  learn_rate = 0.1,
  mtry = NULL,
  min_n = 10L,
  loss_reduction = 0,
  sample_size = 1L,
  stop_iter = 45L,
  engine = c("xgboost", "lightgbm", "ranger"),
  split_prop = 3 / 4,
  grid_levels = 5,
  v_partitions = 10,
  ...,
  .progress = TRUE,
  .date = "date"
) {
  # check inputs
  engine <- rlang::arg_match(engine, multiple = FALSE)
  engine_method <- define_engine_method(engine)
  vars <- rlang::arg_match(
    vars,
    unique(c(dwVars, names(data))),
    multiple = TRUE
  )

  # contain ...
  extra_params <- rlang::list2(...)

  # if any of the vars given aren't in data, they can be appended by the
  # append_dw_vars function
  if (any(!vars %in% names(data))) {
    vars_to_add <- vars[!vars %in% names(data)]
    data <- append_dw_vars(data, vars = vars_to_add, abbr = TRUE, .date = .date)
  }

  # check engine packages
  check_engine_installed(engine)

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

  # define specs, potentially to be overwritten
  tree_depth_spec <- tree_depth
  trees_spec <- trees
  learn_rate_spec <- learn_rate
  mtry_spec <- mtry
  min_n_spec <- min_n
  loss_reduction_spec <- loss_reduction
  sample_size_spec <- sample_size
  stop_iter_spec <- stop_iter

  # start list of fixed params for later
  fixed_params <- list()

  if (length(trees) > 1) {
    grid <- append(grid, list(dials::trees(range = trees)))
    trees_spec <- parsnip::tune()
  } else {
    fixed_params <- append(fixed_params, list(trees = trees))
  }

  if (length(mtry) > 1) {
    grid <- append(grid, list(dials::mtry(range = mtry)))
    mtry_spec <- parsnip::tune()
  } else {
    fixed_params <- append(fixed_params, list(mtry = mtry))
  }

  if (length(min_n) > 1) {
    grid <- append(grid, list(dials::min_n(range = min_n)))
    min_n_spec <- parsnip::tune()
  } else {
    fixed_params <- append(fixed_params, list(min_n = min_n))
  }

  if (engine_method == "boost_tree") {
    if (length(tree_depth) > 1) {
      grid <- append(grid, list(dials::tree_depth(range = tree_depth)))
      tree_depth_spec <- parsnip::tune()
    } else {
      fixed_params <- append(fixed_params, list(tree_depth = tree_depth))
    }

    if (length(learn_rate) > 1) {
      grid <- append(grid, list(dials::learn_rate(range = learn_rate)))
      learn_rate_spec <- parsnip::tune()
    } else {
      fixed_params <- append(fixed_params, list(learn_rate = learn_rate))
    }

    if (length(loss_reduction) > 1) {
      grid <- append(grid, list(dials::loss_reduction(range = loss_reduction)))
      loss_reduction_spec <- parsnip::tune()
    } else {
      fixed_params <- append(
        fixed_params,
        list(loss_reduction = loss_reduction)
      )
    }

    if (engine == "xgboost") {
      if (length(sample_size) > 1) {
        grid <- append(grid, list(dials::sample_size(range = sample_size)))
        sample_size_spec <- parsnip::tune()
      } else {
        fixed_params <- append(fixed_params, list(sample_size = sample_size))
      }

      if (length(stop_iter) > 1) {
        grid <- append(grid, list(dials::stop_iter(range = stop_iter)))
        stop_iter_spec <- parsnip::tune()
      } else {
        fixed_params <- append(fixed_params, list(stop_iter = stop_iter))
      }
    }
  }

  # xgboost handling
  if (engine == "xgboost") {
    alpha <- extra_params$alpha %||% 0
    alpha_spec <- alpha

    lambda <- extra_params$lambda %||% 1
    lambda_spec <- lambda

    if (length(alpha) > 1) {
      grid <- append(
        grid,
        list(dials::penalty_L1(range = alpha))
      )
      alpha_spec <- parsnip::tune()
    } else {
      fixed_params <- append(
        fixed_params,
        list(alpha = alpha)
      )
    }

    if (length(lambda) > 1) {
      grid <- append(
        grid,
        list(dials::penalty_L2(range = lambda))
      )
      lambda_spec <- parsnip::tune()
    } else {
      fixed_params <- append(
        fixed_params,
        list(lambda = lambda)
      )
    }

    engine_params <- list(
      alpha = alpha_spec,
      lambda = lambda_spec
    )
    extra_engine_params <- extra_params[
      !names(extra_params) %in% names(engine_params)
    ]
    engine_params <- append(engine_params, extra_engine_params)
    fixed_params <- append(fixed_params, extra_engine_params)

    tune_spec <-
      parsnip::boost_tree(
        tree_depth = !!tree_depth_spec,
        trees = !!trees_spec,
        learn_rate = !!learn_rate_spec,
        mtry = !!mtry_spec,
        min_n = !!min_n_spec,
        loss_reduction = !!loss_reduction_spec,
        sample_size = !!sample_size_spec,
        stop_iter = !!stop_iter_spec
      ) |>
      parsnip::set_engine(
        engine = engine,
        !!!engine_params
      ) |>
      parsnip::set_mode("regression")
  }

  # lightgbm handling
  if (engine == "lightgbm") {
    num_leaves <- extra_params$num_leaves %||% 31
    num_leaves_spec <- num_leaves

    if (length(num_leaves) > 1) {
      grid <- append(
        grid,
        list(dials::num_leaves(range = num_leaves))
      )
      num_leaves_spec <- parsnip::tune()
    } else {
      fixed_params <- append(
        fixed_params,
        list(num_leaves = num_leaves)
      )
    }

    engine_params <- list(
      num_leaves = num_leaves_spec
    )
    extra_engine_params <- extra_params[
      !names(extra_params) %in% names(engine_params)
    ]
    engine_params <- append(engine_params, extra_engine_params)
    fixed_params <- append(fixed_params, extra_engine_params)

    tune_spec <-
      parsnip::boost_tree(
        tree_depth = !!tree_depth_spec,
        trees = !!trees_spec,
        learn_rate = !!learn_rate_spec,
        mtry = !!mtry_spec,
        min_n = !!min_n_spec,
        loss_reduction = !!loss_reduction_spec
      ) |>
      parsnip::set_engine(
        engine = engine,
        !!!engine_params
      ) |>
      parsnip::set_mode("regression")
  }

  if (engine == "ranger") {
    regularization.factor <- extra_params$regularization.factor %||% 1
    regularization.factor_spec <- regularization.factor

    if (length(regularization.factor) > 1) {
      grid <- append(
        grid,
        list(dials::regularization_factor(range = regularization.factor))
      )
      regularization.factor_spec <- parsnip::tune()
    } else {
      fixed_params <- append(
        fixed_params,
        list(regularization.factor = regularization.factor)
      )
    }

    regularization.usedepth <- extra_params$regularization.usedepth %||% FALSE
    regularization.usedepth_spec <- regularization.usedepth

    if (length(regularization.usedepth) > 1) {
      grid <- append(
        grid,
        list(dials::regularize_depth(values = regularization.usedepth))
      )
      regularization.usedepth_spec <- parsnip::tune()
    } else {
      fixed_params <- append(
        fixed_params,
        list(regularization.usedepth = regularization.usedepth)
      )
    }

    alpha <- extra_params$alpha %||% 0.5
    alpha_spec <- alpha

    if (length(alpha) > 1) {
      grid <- append(
        grid,
        list(dials::significance_threshold(range = alpha))
      )
      alpha_spec <- parsnip::tune()
    } else {
      fixed_params <- append(
        fixed_params,
        list(alpha = alpha)
      )
    }

    minprop <- extra_params$minprop %||% 0.1
    minprop_spec <- minprop

    if (length(minprop) > 1) {
      grid <- append(
        grid,
        list(dials::lower_quantile(range = minprop))
      )
      minprop_spec <- parsnip::tune()
    } else {
      fixed_params <- append(
        fixed_params,
        list(minprop = minprop)
      )
    }

    splitrule <- extra_params$splitrule %||% NULL
    splitrule_spec <- splitrule

    if (length(splitrule) > 1) {
      grid <- append(
        grid,
        list(dials::splitting_rule(values = splitrule))
      )
      splitrule_spec <- parsnip::tune()
    } else {
      fixed_params <- append(
        fixed_params,
        list(splitrule = splitrule)
      )
    }

    num.random.splits <- extra_params$num.random.splits %||% 1
    num.random.splits_spec <- num.random.splits

    if (length(num.random.splits) > 1) {
      grid <- append(
        grid,
        list(dials::num_random_splits(range = num.random.splits))
      )
      num.random.splits_spec <- parsnip::tune()
    } else {
      fixed_params <- append(
        fixed_params,
        list(num.random.splits = num.random.splits)
      )
    }

    engine_params <- list(
      regularization.factor = regularization.factor_spec,
      regularization.usedepth = regularization.usedepth_spec,
      alpha = alpha_spec,
      minprop = minprop_spec,
      splitrule = splitrule_spec,
      num.random.splits = num.random.splits_spec
    )
    extra_engine_params <- extra_params[
      !names(extra_params) %in% names(engine_params)
    ]
    engine_params <- append(engine_params, extra_engine_params)
    fixed_params <- append(fixed_params, extra_engine_params)

    tune_spec <-
      parsnip::rand_forest(
        trees = !!trees_spec,
        mtry = !!mtry_spec,
        min_n = !!min_n_spec
      ) |>
      parsnip::set_engine(
        engine = engine,
        !!!engine_params
      ) |>
      parsnip::set_mode("regression")
  }

  # get training folds
  folds <- rsample::vfold_cv(data_train, v = v_partitions)

  # build a formula object from poll & vars
  formula <- stats::reformulate(vars, pollutant)

  # create tuning workflow
  wf <-
    workflows::workflow() |>
    workflows::add_model(tune_spec) |>
    workflows::add_formula(formula)

  # deal with grid
  if (length(grid) == 0) {
    grid <- 1L
  } else {
    grid <- dials::grid_regular(x = grid, levels = grid_levels)

    # reconcile parsnip names with engine-specific names
    names(grid) <- dplyr::case_match(
      names(grid),
      "regularization_factor" ~ "regularization.factor",
      "regularize_depth" ~ "regularization.usedepth",
      "significance_threshold" ~ "alpha",
      "lower_quantile" ~ "minprop",
      "splitting_rule" ~ "splitrule",
      "num_random_splits" ~ "num.random.splits",
      "penalty_L2" ~ "lambda",
      "penalty_L1" ~ "alpha",
      "num_leaves" ~ "num_leaves",
      .default = names(grid)
    )
  }

  # get results from grid
  results <- tune::tune_grid(
    wf,
    resamples = folds,
    grid = grid,
    control = tune::control_grid(
      verbose = .progress,
      allow_par = TRUE,
      parallel_over = "everything"
    )
  )

  # get metrics
  metrics <- tune::collect_metrics(results) |>
    dplyr::select(-".config", -".estimator") |>
    dplyr::rename("metric" = ".metric")

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
    openair::modStats() |>
    dplyr::rename_with(tolower) |>
    dplyr::select(-dplyr::any_of("default"))

  # return output
  out <- list(
    pollutant = pollutant,
    vars = list(
      names = vars,
      types = as.character(purrr::map(data, class)[vars])
    ),
    best_params = append(
      as.list(best_params),
      fixed_params
    ),
    metrics = metrics,
    final_fit = list(
      predictions = final_predictions,
      metrics = final_metrics
    ),
    engine = list(
      engine = engine,
      method = define_engine_method(engine)
    )
  )

  class(out) <- "TuneDeweather"

  return(out)
}
