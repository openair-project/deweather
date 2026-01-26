# Deweather ---------------------------------------------------------------

#' @method print Deweather
#' @export
#' @author Jack Davison
print.Deweather <- function(x, ...) {
  if (x$engine$method == "boost_tree") {
    labs <-
      get_dw_importance(x, aggregate_factors = TRUE, sort = TRUE) |>
      dplyr::arrange(dplyr::desc(.data$importance)) |>
      dplyr::mutate(
        importance = scales::label_percent(0.1)(.data$importance),
        lab = paste0(.data$var, " (", .data$importance, ")")
      ) |>
      dplyr::pull("lab")
  } else {
    labs <-
      get_dw_importance(x, aggregate_factors = TRUE, sort = TRUE) |>
      dplyr::arrange(dplyr::desc(.data$importance)) |>
      dplyr::pull("var")
  }

  str <- c(
    "*" = "A model for predicting {.strong {get_dw_pollutant(x)}} using {.field {labs}}."
  )

  cli::cli_h1("Deweather Model")
  cli::cli_text(str)

  cli::cli_h2("Model Parameters")

  params <- x$params

  cli::cli_ul()
  for (i in names(params)) {
    cli::cli_li("{.field {i}}: {params[i]}")
  }
  cli::cli_end()
}

#' @method plot Deweather
#' @export
plot.Deweather <- function(x, ...) {
  plot_dw_importance(x, ...)
}

#' @method summary Deweather
#' @export
summary.Deweather <- function(object, ...) {
  dw_map(object$data, summary, ...)
}

#' @method head Deweather
#' @export
head.Deweather <- function(x, ...) {
  dw_map(x$data, utils::head, ...)
}

#' @method tail Deweather
#' @export
tail.Deweather <- function(x, ...) {
  dw_map(x$data, utils::tail, ...)
}

# Tuned -------------------------------------------------------------------

#' @method print TuneDeweather
#' @export
#' @author Jack Davison
print.TuneDeweather <- function(x, ...) {
  cli::cli_h1("Deweather Tuning")
  cli::cli_text(
    "A tuning object for finding appropriate hyperparameters for predicting {.strong {get_tdw_pollutant(x)}} using {.field {get_tdw_vars(x)}}."
  )
  cli::cli_ul(
    c(
      "Use {.fun deweather::get_tdw_best_params} to see the 'best' parameters.",
      "Use {.fun deweather::get_tdw_tuning_metrics} to see the a summary of tuning results.",
      "Use {.fun deweather::plot_tdw_tuning_metrics} and {.fun deweather::plot_tdw_testing_scatter} to visualise this object."
    )
  )
}

#' @method plot TuneDeweather
#' @export
plot.TuneDeweather <- function(x, ...) {
  plot_tdw_tuning_metrics(x, ...)
}

#' @method summary TuneDeweather
#' @export
summary.TuneDeweather <- function(object, ...) {
  get_tdw_tuning_metrics(object, ...)
}

# Utilities ---------------------------------------------------------------

#' mapping helper to perform functions on each dataframe element of a DW model
#' @noRd
#' @author Jack Davison
dw_map <- function(x, FUN, ...) {
  dat <- names(x)

  out <- list()
  for (i in dat) {
    args <- list(x[[i]], ...)
    proc <- do.call(FUN, args = args)
    cli::cli_par(id = i)
    cli::cli_inform(paste0("{.field $", i, "}"))
    print(proc)
    cli::cli_end(id = i)
    out <- append(out, list(proc))
  }

  names(out) <- dat
  return(invisible(out))
}

#' Check an input is a deweather model
#' @noRd
check_deweather <- function(
  dw,
  what = c("Deweather", "TuneDeweather")
) {
  what <- rlang::arg_match(what)

  if (what == "Deweather") {
    if (!inherits(dw, what)) {
      cli::cli_abort(
        "{.arg dw} must be a '{what}' object created using {.fun deweather::build_dw_model}."
      )
    }
  }

  if (what == "TuneDeweather") {
    if (!inherits(dw, what)) {
      cli::cli_abort(
        "{.arg tdw} must be a '{what}' object created using {.fun deweather::tune_dw_model}."
      )
    }
  }
}
