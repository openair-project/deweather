test_that("tuning works", {
  tunedata <- head(deweather::aqroadside, n = 100)

  expect_error(tune_dw_model(tunedata, "no2"))

  tuned <-
    with(
      mirai::daemons(4),
      tune_dw_model(
        tunedata,
        "no2",
        tree_depth = c(1, 5),
        trees = c(150, 250),
        grid_levels = 2
      )
    )

  expect_named(tuned)

  expect_equal(names(tuned), c("best_params", "final_fit"))

  expect_equal(names(tuned$best_params), c("trees", "tree_depth"))

  expect_equal(names(tuned$final_fit), c("predictions", "metrics", "plot"))

  expect_s3_class(tuned$final_fit$predictions, "data.frame")
  expect_s3_class(tuned$final_fit$metrics, "data.frame")
  expect_s3_class(tuned$final_fit$plot, "gg")
})
