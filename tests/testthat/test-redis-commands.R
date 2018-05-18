context("Redis commands")

test_that("Redis commands", {
  expect_is(redis, "redis_commands")
  expect_error(redis$new <- 1, "locked environment")
  expect_identical(redis$PING(), list("PING", NULL))
})

test_that("Filter", {
  tmp <- redis_commands(identity)
  expect_lt(length(filter_redis_commands(tmp, "1.0.0")),
            length(tmp))
  expect_equal(length(filter_redis_commands(tmp, "0.9.9")), 0)

  mv <- unname(max(cmd_since))
  expect_equal(length(filter_redis_commands(tmp, mv)),
               length(tmp))
  expect_equal(length(filter_redis_commands(tmp, as.character(mv))),
               length(tmp))

  con <- test_hiredis_connection()
  v <- redis_version(con)
  ans1 <- filter_redis_commands(tmp, TRUE, con$command)
  ans2 <- filter_redis_commands(tmp, v)
  expect_equal(sort(names(ans1)),
               sort(names(ans2)))
})

test_that("filter -- sanity checking", {
  expect_error(filter_redis_commands(redis_commands(identity), TRUE),
               "No redis connection to get version from")
})

test_that("subscribe", {
  expect_error(redis$SUBSCRIBE("foo"),
               "Do not use SUBSCRIBE")
  expect_error(redis$SUBSCRIBE(),
               "Do not use SUBSCRIBE")
})
