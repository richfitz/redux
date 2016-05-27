context("RcppRedis")

test_that("connection", {
  skip_if_no_rcppredis()

  con <- rcppredis_connection()
  expect_is(con, "redis_connection")
  expect_identical(attr(con, "type", exact=TRUE), "RcppRedis")
  expect_is(con$config(), "redis_config")
  expect_is(con$reconnect, "function")
  expect_is(con$command, "function")

  expect_identical(con$command("PING"), "PONG")
})

test_that("redis_api", {
  skip_if_no_rcppredis()

  con <- redis_api(rcppredis_connection())
  expect_is(con, "redis_api")
  expect_identical(con$type(), "RcppRedis")
  expect_identical(con$PING(), "PONG")

  keys <- paste0("redis_api_test:", letters)
  con$MSET(keys, LETTERS)
  expect_identical(con$MGET(keys), as.list(LETTERS))
  expect_equal(con$DEL(keys), length(LETTERS))
})

test_that("unimplemented functions", {
  skip_if_no_rcppredis()
  con <- redis_api(rcppredis_connection())
  expect_error(con$pipeline(
    redis$PING(),
    redis$PING()),
    "pipeline is not supported with the RcppRedis interface")
  expect_error(
    con$subscribe("foo"),
    "subscribe is not supported with the RcppRedis interface")
})

test_that("filter version", {
  skip_if_no_rcppredis()
  x1 <- redis_api(rcppredis_connection(), "1.0.0")
  x2 <- redis_api(rcppredis_connection(), "2.0.0")
  expect_lt(length(x1), length(x2))

  our_ver <- redis_version(x1)
  max_ver <- unname(max(cmd_since))

  x3 <- redis_api(rcppredis_connection(), TRUE)
  expect_equal(length(x3) > length(x2),
               our_ver > numeric_version("2.0.0"))

  x4 <- redis_api(rcppredis_connection())
  expect_equal(length(x4) > length(x3),
               max_ver > our_ver)
})

test_that("simple interface", {
  skip_if_no_rcppredis()
  con <- rcppredis_hiredis(version=TRUE)
  expect_is(con, "redis_api")
})
