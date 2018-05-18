context("print")

test_that("redis_commands", {
  str <- capture_output(print(redis))
  expect_match(str, "redis_commands")
  expect_match(str, "PING")
})

test_that("redis_api", {
  con <- test_hiredis_connection()
  str <- capture_output(print(con))
  expect_match(str, "redis_api")
  expect_match(str, "PING")
  expect_match(str, "Other public methods")
})

test_that("redis_connection", {
  skip_if_no_redis()
  con <- redis_connection()
  str <- capture_output(print(con))
  expect_match(str, "redis_connection")
})
