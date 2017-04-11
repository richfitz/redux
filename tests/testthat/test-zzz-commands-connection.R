context("commands - connection")

test_that("AUTH", {
  pw <- rand_str()
  expect_equal(redis_cmds$AUTH(pw), list("AUTH", pw))
})

test_that("ECHO", {
  str <- rand_str()
  expect_equal(redis_cmds$ECHO(str), list("ECHO", str))
})

test_that("PING", {
  expect_equal(redis_cmds$PING(), list("PING", NULL))
})

test_that("QUIT", {
  expect_equal(redis_cmds$QUIT(), list("QUIT"))
})

test_that("SELECT", {
  expect_equal(redis_cmds$SELECT(1), list("SELECT", 1))
})
