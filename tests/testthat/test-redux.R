context("main entry points")

test_that("redis_connection", {
  con <- redis_connection()
  expect_that(setequal(names(con),
                       c("config", "reconnect", "command",
                         "pipeline", "subscribe")),
              is_true())
  expect_that(con$command("PING"), equals(redis_status("PONG")))

  tmp <- unserialize(serialize(con, NULL))
  expect_that(tmp$command("PING"), throws_error("Context is not connected"))
  tmp$reconnect()
  expect_that(con$command("PING"), equals(redis_status("PONG")))
})
