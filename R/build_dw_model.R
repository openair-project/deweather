#' Build a Deweather Model
#'
#' This function builds a 'deweathering' machine learning model with useful
#' methods for interrogating it in an air quality and meteorological context. It
#' uses any number of variables (most usefully meteorological variables like
#' wind speed and wind direction and temporal variables defined in
#' [append_dw_vars()]) to fit a model predicting a given `pollutant`. While
#' these models are useful for 'removing' the effects of meteorology from an air
#' quality time series (e.g., through [simulate_dw_met()]), they are also useful
#' for explanatory analysis (e.g., through [plot_dw_partial_1d()]).
#'
#' @param data An input `data.frame` containing one pollutant column (defined
#'   using `pollutant`) and a collection of feature columns (defined using
#'   `vars`).
#'
#' @param pollutant The name of the column (likely a pollutant) in `data` to
#'   predict.
#'
#' @param vars The name of the columns in `data` to use as model features -
#'   i.e., to predict the values in the `pollutant` column. Any character
#'   columns will be coerced to factors. `"hour"`, `"weekday"`, `"trend"`,
#'   `"yday"`, `"week"`, and `"month"` are special terms and will be passed to
#'   [append_dw_vars()] if not present in `names(data)`.
#'
#' @param mtry Number of Randomly Selected Predictors
#'   `<xgboost|lightgbm|ranger>`
#'
#'   A number for the number (or proportion) of predictors that will be randomly
#'   sampled at each split when creating the tree models.
#'
#' @param trees Number of Trees `<xgboost|lightgbm|ranger>`
#'
#'   An integer for the number of trees contained in the ensemble.
#'
#' @param min_n Minimal Node Size `<xgboost|lightgbm|ranger>`
#'
#'   An integer for the minimum number of data points in a node that is required
#'   for the node to be split further.
#'
#' @param tree_depth Tree Depth `<xgboost|lightgbm>`
#'
#'   An integer for the maximum depth of the tree (i.e., number of splits).
#'
#' @param learn_rate Learning Rate `<xgboost|lightgbm>`
#'
#'   A number for the rate at which the boosting algorithm adapts from
#'   iteration-to-iteration. This is sometimes referred to as the shrinkage
#'   parameter.
#'
#' @param loss_reduction Minimum Loss Reduction `<xgboost|lightgbm>`
#'
#'   A number for the reduction in the loss function required to split further.
#'
#' @param sample_size Proportion Observations Sampled `<xgboost>`
#'
#'   A number for the number (or proportion) of data that is exposed to the
#'   fitting routine.
#'
#' @param stop_iter Number of Iterations Before Stopping `<xgboost>`
#'
#'   The number of iterations without improvement before stopping.
#'
#' @param engine A single character string specifying what computational engine
#'   to use for fitting. Can be `"xgboost"`, `"lightgbm"` (boosted trees) or
#'   `"ranger"` (random forest). See the documentation below for more
#'   information.
#'
#' @param ... Used to pass additional engine-specific parameters to the model
#'   (for example, `lambda` for the `xgboost` engine). Currently, these
#'   engine-specific parameters cannot be 'tuned' in [tune_dw_model()].
#'
#' @param .date The name of the 'date' column which defines the air quality
#'   timeseries. Passed to [append_dw_vars()] if needed. Also used to extract
#'   the time zone of the data for later restoration if `trend` is used as a
#'   variable.
#'
#' @section Modelling Approaches and Parameters:
#'
#'   ## Types of Model
#'
#'   There are two modelling approaches available to [build_dw_model()]:
#'
#'   - Boosted Trees (`xgboost`, `lightgbm`)
#'
#'   - Random Forest (`ranger`)
#'
#'   Each of these approaches take different parameters.
#'
#'   ## Boosted Trees
#'
#'   Two engines are available for boosted tree models:
#'
#'   - `"xgboost"`
#'
#'   - `"lightgbm"`
#'
#'   The following parameters apply:
#'
#'   - `tree_depth`: Tree Depth
#'
#'   - `trees`: # Trees
#'
#'   - `learn_rate`: Learning Rate
#'
#'   - `mtry`: # Randomly Selected Predictors
#'
#'   - `min_n`: Minimal Node Size
#'
#'   - `loss_reduction`: Minimum Loss Reduction
#'
#'   - `sample_size`: Proportion Observations Sampled (`xgboost` only)
#'
#'   - `stop_iter`: # Iterations Before Stopping (`xgboost` only)
#'
#'   ## Random Forest
#'
#'   One engine is available for random forest models:
#'
#'   - `"ranger"`
#'
#'   The following parameters apply:
#'
#'   - `mtry`: # Randomly Selected Predictors
#'
#'   - `trees`: # Trees
#'
#'   - `min_n`: Minimal Node Size
#'
#' @return a 'Deweather' object for further analysis
#'
#' @seealso [finalise_tdw_model()]
#' @export
build_dw_model <- function(
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
  ...,
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

  # get timezone
  tz <- lubridate::tz(data[[.date]])

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

  # define model spec
  if (engine_method == "boost_tree") {
    model_spec <-
      parsnip::boost_tree(
        tree_depth = !!tree_depth,
        trees = !!trees,
        learn_rate = !!learn_rate,
        mtry = !!mtry,
        min_n = !!min_n,
        loss_reduction = !!loss_reduction,
        sample_size = !!sample_size,
        stop_iter = !!stop_iter
      ) |>
      parsnip::set_engine(
        engine,
        ...
      ) |>
      parsnip::set_mode("regression")

    # list parameters
    params <- list(
      tree_depth = tree_depth,
      trees = trees,
      learn_rate = learn_rate,
      mtry = mtry,
      min_n = min_n,
      loss_reduction = loss_reduction
    )

    # if xgboost, also include extra 2 params
    if (engine == "xgboost") {
      params <- append(
        params,
        list(
          sample_size = sample_size,
          stop_iter = stop_iter
        )
      )
    }
  }

  if (engine_method == "rand_forest") {
    model_spec <-
      parsnip::rand_forest(
        engine = engine,
        trees = !!trees,
        mtry = !!mtry,
        min_n = !!min_n
      ) |>
      parsnip::set_engine(
        engine,
        ...
      ) |>
      parsnip::set_mode("regression")

    # need a second spec for importance calcs
    model_spec_importance <-
      parsnip::rand_forest(
        trees = !!trees,
        mtry = !!mtry,
        min_n = !!min_n
      ) |>
      parsnip::set_engine(
        engine = engine,
        importance = "impurity_corrected",
        ...
      ) |>
      parsnip::set_mode("regression")

    # list parameters - only three
    params <- list(
      trees = trees,
      mtry = mtry,
      min_n = min_n
    )
  }

  # add ... to params, if used
  params <- append(params, rlang::list2(...))

  # build a formula object from poll & vars
  formula <- stats::reformulate(vars, pollutant)

  # fit the model
  model <- parsnip::fit(model_spec, formula, data = data)

  if (engine_method == "boost_tree") {
    # get importance
    importance <- vip::vi(model$fit) |>
      stats::setNames(c("var", "importance"))
  } else {
    # get importance
    importance <- parsnip::fit(model_spec_importance, formula, data = data) |>
      purrr::pluck("fit") |>
      vip::vi() |>
      stats::setNames(c("var", "importance"))
  }

  # reverse the factor levels (for plotting mainly)
  importance$var <- factor(importance$var, rev(importance$var))

  # deweather object
  out <- list(
    pollutant = pollutant,
    vars = list(
      names = vars,
      types = as.character(purrr::map(data, class)[vars])
    ),
    params = params,
    data = list(
      input = data,
      importance = dplyr::tibble(importance)
    ),
    model = model,
    engine = list(
      engine = engine,
      method = engine_method
    ),
    tz = tz
  )

  class(out) <- "Deweather"

  return(out)
}
