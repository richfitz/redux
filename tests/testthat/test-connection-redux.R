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

test_that("connection timeout over tcp returns sensible error", {
  skip_if_no_redis()
  cfg <- redis_config(host = "example.com", timeout = 1000)
  ## The error here *might* say
  ##
  ##     Failed to create context: Connection timed out
  ##
  ## or similar, but this seems very dependent on (presumably) hiredis
  ## client versions and platforms.  On windows we only see "unknown
  ## error" and on mac the string differs slightly.  We don't control
  ## the exact message so should just report on the part we do control.
  t <- system.time(
    expect_error(
      redis_connection(cfg),
      "Failed to create context"))

  ## These are likely to prove a bit flakey due to the usual issues
  ## with timing.
  expect_lt(t[["elapsed"]], 2)
  expect_gte(t[["elapsed"]], 1)
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
