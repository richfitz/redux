context("connection")

test_that("redis_connection", {
  skip_if_no_redis()
  con <- redis_connection()
  expect_true(setequal(names(con),
                       c("config", "reconnect", "command",
                         "pipeline", "subscribe")))
  expect_equal(con$command("PING"), redis_status("PONG"))

  tmp <- unserialize(serialize(con, NULL))
  expect_error(tmp$command("PING"), "Context is not connected")
  tmp$reconnect()
  expect_equal(con$command("PING"), redis_status("PONG"))

  ## Very trivial tests of the other methods:
  expect_is(con$config(), "redis_config")
  expect_equal(con$pipeline(list("PING", "PING")),
               rep(list(redis_status("PONG")), 2))
})

test_that("impossible connection", {
  skip_if_no_redis()
  expect_error(redis_connection(redis_config(port = 99999)),
               "Failed to create context")
  expect_error(redis_connect_unix(tempfile()),
               "Failed to create context")
})

test_that("auth", {
  skip_if_no_redis()
  expect_error(redis_connection(redis_config(password = "foo")),
               "no password is set")
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
