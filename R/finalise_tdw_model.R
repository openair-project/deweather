#' Use the 'best parameters' determined by [tune_dw_model()] to build a
#' Deweather Model
#'
#' This function takes the output of [tune_dw_model()] and uses the
#' `best_params` defined within. This is a convenient wrapper around
#' [build_dw_model()] if you have already run [tune_dw_model()] and are broadly
#' happy with the parameters it has chosen. That being said, the `params`
#' argument can be used to override specific hyperparameters.
#'
#' @param tdw A deweather tuning object created with [tune_dw_model()].
#'
#' @param data An input `data.frame` containing one pollutant column (defined
#'   using `pollutant`) and a collection of feature columns (defined using
#'   `vars`). This must be provided in addition to `tdw` as it is expected most
#'   users will have provided [tune_dw_model()] with a sampled dataset.
#'
#' @param params A named list. These parameters are used to override the
#'   `best_params` defined within `tdw`. For example, if the 'best' parameter
#'   for `trees` is 50, `params = list(trees = 100)` will set it to 100 instead.
#'
#' @inheritParams build_dw_model
#'
#' @seealso [build_dw_model()]
#' @author Jack Davison
#' @export
finalise_tdw_model <- function(
  tdw,
  data,
  params = list(),
  ...,
  .date = "date"
) {
  pollutant <- get_tdw_pollutant(tdw)
  vars <- get_tdw_vars(tdw)
  engine <- get_tdw_engine(tdw)
  best_params <- get_tdw_best_params(tdw)

  build_dw_model(
    data = data,
    pollutant = pollutant,
    vars = vars,
    tree_depth = params$tree_depth %||% best_params$tree_depth,
    trees = params$trees %||% best_params$trees,
    learn_rate = params$learn_rate %||% best_params$learn_rate,
    mtry = params$mtry %||% best_params$mtry,
    min_n = params$min_n %||% best_params$min_n,
    loss_reduction = params$loss_reduction %||% best_params$loss_reduction,
    sample_size = params$sample_size %||% best_params$sample_size,
    stop_iter = params$stop_iter %||% best_params$stop_iter,
    engine = engine,
    .date = .date
  )
}
