context("main entry points")

test_that("redis_connection", {
  ## Ordinarily this would be done with RedisAPI but that generates a
  ## circular dependency.  Suggests might be OK here though.
  config <- list(host="localhost", port=6379L, scheme="redis")
  con <- redis_connection(config)
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
