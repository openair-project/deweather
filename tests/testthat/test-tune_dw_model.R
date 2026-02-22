test_that("tuning works", {
  # create reduced data for tuning
  tunedata <- head(deweather::aqroadside, n = 200)

  # expect a warning if you don't actually tune anything
  expect_warning(tune_dw_model(tunedata, "no2"))

  # loop over engines
  for (engine in c("xgboost", "ranger")) {
    # tune data
    tuned <-
      with(
        mirai::daemons(4),
        tune_dw_model(
          tunedata,
          "no2",
          tree_depth = c(5, 10),
          min_n = c(5, 10),
          grid_levels = 2,
          engine = engine
        )
      )

    # should be a named list
    expect_named(tuned)

    # expected items
    expect_named(
      tuned,
      c("pollutant", "vars", "best_params", "metrics", "final_fit", "engine")
    )

    # all params should be present
    if (engine == "xgboost") {
      expect_named(
        tuned$best_params,
        c(
          "min_n",
          "tree_depth",
          "trees",
          "mtry",
          "learn_rate",
          "loss_reduction",
          "sample_size",
          "stop_iter",
          "alpha",
          "lambda"
        )
      )
    } else {
      expect_named(
        tuned$best_params,
        c(
          "min_n",
          "trees",
          "mtry",
          "regularization.factor",
          "regularization.usedepth",
          "alpha",
          "minprop",
          "splitrule",
          "num.random.splits"
        )
      )
    }

    # getters
    expect_identical(tuned$engine$engine, engine)

    expect_named(tuned$final_fit, c("predictions", "metrics"))

    expect_s3_class(tuned$final_fit$predictions, "data.frame")
    expect_s3_class(tuned$final_fit$metrics, "data.frame")
  }
})
