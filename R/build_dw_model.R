#' Build a Deweather Model
#'
#' This function builds a boosted decision tree machine learning model with
#' useful methods for interrogating it in an air quality and meteorological
#' context. Currently, only the [xgboost][xgboost::xgboost()] engine is
#' supported.
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
#' @param ... Not current used.
#'
#' @param .date The name of the 'date' column which defines the air quality
#'   timeseries. Passed to [append_dw_vars()] if needed. Also used to extract
#'   the time zone of the data for later restoration if `trend` is used as a
#'   variable.
#'
#' @inheritParams parsnip::boost_tree
#'
#' @return a 'Deweather' object for further analysis
#'
#' @export
build_dw_model <- function(
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
  ...,
  .date = "date"
) {
  # check inputs
  rlang::check_dots_empty()
  engine <- rlang::arg_match(engine, multiple = FALSE)
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
  model_spec <-
    parsnip::boost_tree(
      mode = "regression",
      engine = engine,
      tree_depth = !!tree_depth,
      trees = !!trees,
      learn_rate = !!learn_rate,
      mtry = !!mtry,
      min_n = !!min_n,
      loss_reduction = !!loss_reduction,
      sample_size = !!sample_size,
      stop_iter = !!stop_iter
    )

  # build a formula object from poll & vars
  formula <- stats::reformulate(vars, pollutant)

  # fit the model
  model <- parsnip::fit(model_spec, formula, data = data)

  # get importance
  importance <- vip::vi(model$fit) |>
    stats::setNames(c("var", "importance"))

  # reverse the factor levels (for plotting mainly)
  importance$var <- factor(importance$var, rev(importance$var))

  # deweather object
  out <- list(
    pollutant = pollutant,
    vars = list(
      names = vars,
      types = as.character(purrr::map(data, class)[vars])
    ),
    params = list(
      tree_depth = tree_depth,
      trees = trees,
      learn_rate = learn_rate,
      mtry = mtry,
      min_n = min_n,
      loss_reduction = loss_reduction,
      sample_size = sample_size,
      stop_iter = stop_iter
    ),
    data = list(
      input = data,
      importance = dplyr::tibble(importance)
    ),
    model = model,
    engine = "xgboost",
    tz = tz
  )

  class(out) <- "Deweather"

  return(out)
}
