context("commands - cluster")

test_that("PSUBSCRIBE", {
  ## TODO: throw an error here too
  expect_equal(redis_cmds$PSUBSCRIBE("*foo*"),
               list("PSUBSCRIBE", "*foo*"))
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
  skip_if_no_redis()
  con <- hiredis()
  expect_error(con$SUBSCRIBE("channel"),
               "Do not use SUBSCRIBE")

})

test_that("UNSUBSCRIBE", {
  expect_equal(redis_cmds$UNSUBSCRIBE("channel"),
               list("UNSUBSCRIBE", "channel"))
})
