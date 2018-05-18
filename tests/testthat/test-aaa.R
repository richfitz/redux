context("redux (basic test)")

test_that("use", {
  r <- test_hiredis_connection()
  expect_equal(r$PING(), redis_status("PONG"))
  key <- "redisapi-test:foo"
  expect_equal(r$SET(key, "bar"), redis_status("OK"))
  expect_equal(r$GET(key), "bar")
  r$DEL(key)
})
