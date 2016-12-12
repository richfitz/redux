context("commands - transactions")

test_that("DISCARD", {
  expect_equal(redis_cmds$DISCARD(), list("DISCARD"))
})

test_that("EXEC", {
  expect_equal(redis_cmds$EXEC(), list("EXEC"))
})

test_that("MULTI", {
  expect_equal(redis_cmds$MULTI(), list("MULTI"))
})

test_that("UNWATCH", {
  expect_equal(redis_cmds$UNWATCH(), list("UNWATCH"))
})

test_that("WATCH", {
  expect_equal(redis_cmds$WATCH("aa"), list("WATCH", "aa"))
  expect_equal(redis_cmds$WATCH(c("aa", "bb")), list("WATCH", c("aa", "bb")))
})
