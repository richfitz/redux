context("storr")

test_that("redis_api", {
  skip_if_no_redis()
  con <- redux::hiredis()
  storr::test_driver(function(dr = NULL, ...)
    driver_redis_api(dr$prefix %||% rand_str(), con, ...))
})

test_that("storr_redis_api", {
  st <- storr_redis_api(rand_str(), redux::hiredis())
  on.exit(st$destroy())
  expect_is(st, "storr")
  expect_equal(st$driver$type(), "redis_api/redux")
})
