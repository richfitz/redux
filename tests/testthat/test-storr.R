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
