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
})
