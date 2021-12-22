context("connection, redux")

test_that("impossible connection", {
  skip_if_no_redis()
  expect_error(redis_connection(redis_config(port = 99999)),
               "Failed to create context")
  ## this does not trigger on windows with hiredis v1, for unknown
  ## reasons
  skip_on_os("windows")
  expect_error(redis_connect_unix(tempfile()),
               "Failed to create context")
})

test_that("connection timeout", {
  expect_error(redis_connection(
    redis_config(host = "1.2.3.4", port = 99999, timeout = 1000)),
               "Failed to create context: Connection timed out")

  expect_true({
    t <- system.time({
      try(redis_connection(
        redis_config(host = "1.2.3.4", port = 99999, timeout = 1000)),
      silent = TRUE)
    })
    t[["elapsed"]] < 1.1
  })
})

test_that("auth", {
  skip_if_no_redis()
  expect_error(redis_connection(redis_config(password = "foo")))
})

test_that("select db", {
  skip_if_no_redis()
  con0 <- hiredis(redis_config(db = 0L))
  con1 <- hiredis(redis_config(db = 1L))
  key <- rand_str()
  con1$SET(key, "db1")
  on.exit(con1$DEL(key))
  expect_equal(con0$EXISTS(key), 0)
  expect_equal(con1$EXISTS(key), 1)
  con0$SELECT(1)
  expect_equal(con0$EXISTS(key), 1)
})
