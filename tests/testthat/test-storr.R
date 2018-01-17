context("storr")

test_that("redis_api", {
  con <- test_hiredis_connection()
  storr::test_driver(function(dr = NULL, ...)
    driver_redis_api(dr$prefix %||% rand_str(), con, ...))
})

test_that("storr_redis_api", {
  con <- test_hiredis_connection()
  st <- storr_redis_api(rand_str(), con)
  on.exit(st$destroy())
  expect_is(st, "storr")
  expect_equal(st$driver$type(), "redis_api/redux")
})

test_that("driver from config", {
  skip_if_no_redis()
  prefix <- rand_str()
  dr <- driver_redis_api(prefix, NULL)
  expect_identical(dr$con$config(), redis_config())

  dr <- driver_redis_api(prefix, list(db = 1))
  expect_identical(dr$con$config(), redis_config(db = 1))

  dr <- driver_redis_api(prefix, redis_config(db = 2))
  expect_identical(dr$con$config(), redis_config(db = 2))

  expect_error(driver_redis_api(prefix)) # missing
  expect_error(driver_redis_api(prefix, 1L),
               "Invalid input for 'con'")
})
