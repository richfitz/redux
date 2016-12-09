context("commands - transactions")

test_that("DISCARD", {
  expect_equal(redis$DISCARD(), list("DISCARD"))
})

test_that("DISCARD", {
  expect_equal(redis$EXEC(), list("EXEC"))
})

test_that("MULTI", {
  expect_equal(redis$MULTI(), list("MULTI"))
})

test_that("UNWATCH", {
  expect_equal(redis$UNWATCH(), list("UNWATCH"))
})

test_that("WATCH", {
  expect_equal(redis$WATCH("aa"), list("WATCH", "aa"))
  expect_equal(redis$WATCH(c("aa", "bb")), list("WATCH", c("aa", "bb")))
})
