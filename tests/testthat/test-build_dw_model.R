test_that("boosted tree models work", {
  small_data <- head(aqroadside, n = 1000)

  model <- build_dw_model(small_data, "no2")

  expect_no_error(print(model))
  expect_no_error(head(model))
  expect_no_error(tail(model))
  expect_no_error(plot(model))
  expect_no_error(summary(model))

  expect_equal(get_dw_engine(model), "xgboost")
  expect_equal(get_dw_pollutant(model), "no2")
  expect_equal(
    get_dw_vars(model),
    c("trend", "ws", "wd", "hour", "weekday", "air_temp")
  )
  expect_equal(
    names(get_dw_input_data(model)),
    c("no2", "trend", "ws", "wd", "hour", "weekday", "air_temp")
  )
  expect_equal(
    get_dw_params(model),
    list(
      tree_depth = 5,
      trees = 200L,
      learn_rate = 0.1,
      mtry = NULL,
      min_n = 10L,
      loss_reduction = 0,
      sample_size = 1L,
      stop_iter = 190L
    )
  )
  expect_equal(get_dw_params(model, "tree_depth"), 5)

  imp <- get_dw_importance(model)
  expect_type(imp$importance, "double")
  expect_s3_class(imp$var, "factor")
  expect_equal(nrow(imp), 12)

  imp2 <- get_dw_importance(model, aggregate_factors = TRUE)
  expect_equal(nrow(imp2), length(get_dw_vars(model)))

  imp3 <- get_dw_importance(model, sort = FALSE)
  expect_type(imp3$var, "character")

  expect_no_error(plot_dw_importance(model))
  expect_no_error(plot_dw_importance(model, aggregate_factors = TRUE))

  expect_s3_class(plot_dw_partial_1d(model, n = 10), "gg")
  expect_s3_class(plot_dw_partial_1d(model, "hour", n = 10), "gg")
  expect_s3_class(plot_dw_partial_1d(model, c("hour", "ws"), n = 10), "gg")

  expect_s3_class(plot_dw_partial_2d(model, "hour", "ws", n = 10), "gg")
  expect_s3_class(
    plot_dw_partial_2d(model, "hour", "ws", n = 10, contour = "lines"),
    "gg"
  )
  expect_s3_class(
    plot_dw_partial_2d(model, "hour", "ws", n = 10, contour = "fill"),
    "gg"
  )
  expect_s3_class(
    plot_dw_partial_2d(model, "hour", "ws", n = 10, show_conf_int = TRUE),
    "gg"
  )
})
