context("commands - connection")

test_that("AUTH", {
  skip_if_no_redis()
  con <- hiredis()
  pw <- rand_str()
  expect_error(con$AUTH(pw), "no password")
})

test_that("ECHO", {
  skip_if_no_redis()
  con <- hiredis()
  expect_equal(con$ECHO("Hello World!"), "Hello World!")
})

test_that("PING", {
  skip_if_no_redis()
  con <- hiredis()
  expect_equal(con$PING(), redis_status("PONG"))
  ## TODO: recent versions allow an argument
})

test_that("QUIT", {
  expect_equal(redis_cmds$QUIT(), list("QUIT"))
})

## NOTE: not testing QUIT, but it is tested elsewhere
## NOTE: not testing SELECT, but it is tested elsewhere
