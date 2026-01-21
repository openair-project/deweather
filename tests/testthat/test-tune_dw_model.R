test_that("tuning works", {
  tunedata <- head(deweather::aqroadside, n = 200)

  expect_error(tune_dw_model(tunedata, "no2"))

  for (engine in c("xgboost", "ranger")) {
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

    expect_named(tuned)

    expect_equal(
      names(tuned),
      c("pollutant", "vars", "best_params", "metrics", "final_fit", "engine")
    )

    if (engine == "xgboost") {
      expect_equal(names(tuned$best_params), c("min_n", "tree_depth"))
    } else {
      expect_equal(names(tuned$best_params), c("min_n"))
    }

    expect_equal(tuned$engine$engine, engine)

    expect_equal(names(tuned$final_fit), c("predictions", "metrics", "plot"))

    expect_s3_class(tuned$final_fit$predictions, "data.frame")
    expect_s3_class(tuned$final_fit$metrics, "data.frame")
    expect_s3_class(tuned$final_fit$plot, "gg")
  }
})
