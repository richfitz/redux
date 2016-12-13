context("commands - connection")

test_that("AUTH", {
  skip_if_cmd_unsupported("AUTH")
  con <- hiredis()
  pw <- rand_str()
  expect_error(con$AUTH(pw), "no password")
})

test_that("ECHO", {
  skip_if_cmd_unsupported("ECHO")
  con <- hiredis()
  expect_equal(con$ECHO("Hello World!"), "Hello World!")
})

test_that("PING", {
  skip_if_cmd_unsupported("PING")
  con <- hiredis()
  expect_equal(con$PING(), redis_status("PONG"))
  ## TODO: recent versions allow an argument
})

test_that("QUIT", {
  expect_equal(redis_cmds$QUIT(), list("QUIT"))
})

test_that("SELECT", {
  expect_equal(redis_cmds$SELECT(1), list("SELECT", 1))
})
