test_that("appending vars works", {
  vars <- c("hour", "weekday", "trend", "yday", "week", "month")

  appended <- append_dw_vars(
    aqroadside,
    vars = vars
  )

  expect_true(
    all(vars %in% names(appended))
  )

  expect_s3_class(appended$weekday, "factor")
  expect_s3_class(appended$month, "factor")
  expect_type(appended$trend, "double")
  expect_type(appended$hour, "integer")
  expect_type(appended$yday, "integer")
  expect_type(appended$week, "integer")

  expect_error(append_dw_vars(aqroadside, .date = "DATETIME"))

  dummy <- aqroadside
  dummy$date <- as.character(dummy$date)
  expect_error(append_dw_vars(dummy))
})
