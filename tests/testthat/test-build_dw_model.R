small_data <- head(aqroadside, n = 1000)

# test a boosted tree and random forest model
for (engine in c("xgboost", "ranger")) {
  # build the model first
  dw_model <- build_dw_model(small_data, "no2", engine = engine)

  # check that the generics are printing properly
  test_that("generics work", {
    expect_no_error(print(dw_model))
    expect_no_error(head(dw_model))
    expect_no_error(tail(dw_model))
    expect_no_error(plot(dw_model))
    expect_no_error(summary(dw_model))
  })

  # check that we can get the correct part of the deweather object
  test_that("getters work", {
    expect_equal(get_dw_engine(dw_model), engine)
    expect_equal(get_dw_pollutant(dw_model), "no2")
    expect_equal(
      get_dw_vars(dw_model),
      c("trend", "ws", "wd", "hour", "weekday", "air_temp")
    )
    expect_equal(
      names(get_dw_input_data(dw_model)),
      c("no2", "trend", "ws", "wd", "hour", "weekday", "air_temp")
    )

    if (engine == "xgboost") {
      expect_equal(
        get_dw_params(dw_model),
        list(
          tree_depth = 5,
          trees = 50L,
          learn_rate = 0.1,
          mtry = NULL,
          min_n = 10L,
          loss_reduction = 0,
          sample_size = 1L,
          stop_iter = 45L
        )
      )
    }

    if (engine == "ranger") {
      expect_equal(
        get_dw_params(dw_model),
        list(
          trees = 50L,
          mtry = NULL,
          min_n = 10L
        )
      )
    }

    expect_equal(get_dw_params(dw_model, "trees"), 50L)

    # importance is more complex
    imp <- get_dw_importance(dw_model)
    expect_type(imp$importance, "double")
    expect_s3_class(imp$var, "factor")
    expect_equal(nrow(imp), ifelse(engine == "xgboost", 12, 6))

    imp2 <- get_dw_importance(dw_model, aggregate_factors = TRUE)
    expect_equal(nrow(imp2), length(get_dw_vars(dw_model)))

    imp3 <- get_dw_importance(dw_model, sort = FALSE)
    expect_type(imp3$var, "character")
  })

  # plotting functions
  test_that("plots work", {
    expect_no_error(plot_dw_importance(dw_model))
    expect_no_error(plot_dw_importance(dw_model, aggregate_factors = TRUE))

    expect_s3_class(plot_dw_partial_1d(dw_model, n = 10), "gg")
    expect_s3_class(plot_dw_partial_1d(dw_model, "hour", n = 10), "gg")
    expect_s3_class(plot_dw_partial_1d(dw_model, c("hour", "ws"), n = 10), "gg")
    expect_s3_class(
      plot_dw_partial_1d(dw_model, c("hour", "ws"), group = "weekday", n = 10),
      "gg"
    )
    expect_s3_class(
      plot_dw_partial_1d(dw_model, c("hour", "ws"), group = "hour", n = 10),
      "gg"
    )

    expect_s3_class(plot_dw_partial_2d(dw_model, "hour", "ws", n = 10), "gg")
    expect_s3_class(
      plot_dw_partial_2d(dw_model, "hour", "ws", n = 10, contour = "lines"),
      "gg"
    )
    expect_s3_class(
      plot_dw_partial_2d(dw_model, "hour", "ws", n = 10, contour = "fill"),
      "gg"
    )
    expect_s3_class(
      plot_dw_partial_2d(dw_model, "hour", "ws", n = 10, show_conf_int = TRUE),
      "gg"
    )
  })
}
