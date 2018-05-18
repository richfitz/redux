context("commands - scripting")

test_that("EVAL", {
  skip_if_cmd_unsupported("EVAL")
  con <- test_hiredis_connection()

  res <- con$EVAL("return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}", 2,
                  c("key1", "key2"), c("first", "second"))
  expect_equal(res, list("key1", "key2", "first", "second"))
})

test_that("EVALSHA/SCRIPT LOAD", {
  skip_if_cmd_unsupported("EVALSHA")
  con <- test_hiredis_connection()
  key <- rand_str()

  x <- serialize(runif(10), NULL)
  con$SET(key, x)
  on.exit(con$DEL(key))

  sha <- con$SCRIPT_LOAD(sprintf("return redis.call('get', '%s')", key))
  expect_identical(con$EVALSHA(sha, 1, key, NULL), x)

  expect_equal(con$SCRIPT_EXISTS(sha), list(1))

  expect_equal(con$SCRIPT_FLUSH(), redis_status("OK"))

  expect_equal(con$SCRIPT_EXISTS(sha), list(0))
})

test_that("SCRIPT DEBUG", {
  expect_equal(redis_cmds$SCRIPT_DEBUG("YES"),
               list("SCRIPT", "DEBUG", "YES"))
  expect_equal(redis_cmds$SCRIPT_DEBUG("NO"),
               list("SCRIPT", "DEBUG", "NO"))
})

test_that("SCRIPT KILL", {
  expect_equal(redis_cmds$SCRIPT_KILL(),
               list("SCRIPT", "KILL"))
})
