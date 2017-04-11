context("commands - cluster")

test_that("PSUBSCRIBE", {
  expect_error(redis_cmds$PSUBSCRIBE("pat*"),
               "Do not use PSUBSCRIBE")
})

test_that("PUBSUB", {
  expect_equal(redis_cmds$PUBSUB("CHANNELS"),
               list("PUBSUB", "CHANNELS", NULL))
  expect_equal(redis_cmds$PUBSUB("CHANNELS", "*foo*"),
               list("PUBSUB", "CHANNELS", "*foo*"))
  expect_equal(redis_cmds$PUBSUB("NUMSUB"),
               list("PUBSUB", "NUMSUB", NULL))
})

test_that("PUBLISH", {
  expect_equal(redis_cmds$PUBLISH("foo", "bar"),
               list("PUBLISH", "foo", "bar"))
})

test_that("PUNSUBSCRIBE", {
  expect_equal(redis_cmds$PUNSUBSCRIBE("pattern"),
               list("PUNSUBSCRIBE", "pattern"))
})

test_that("SUBSCRIBE", {
  expect_error(redis_cmds$SUBSCRIBE("channel"),
               "Do not use SUBSCRIBE")
})

test_that("UNSUBSCRIBE", {
  expect_equal(redis_cmds$UNSUBSCRIBE("channel"),
               list("UNSUBSCRIBE", "channel"))
})
