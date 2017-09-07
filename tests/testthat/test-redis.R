context("hiredis")

test_that("connection", {
  skip_if_no_redis()
  ptr <- redis_connect_tcp(REDIS_HOST, REDIS_PORT)
  ## Dangerous raw pointer:
  expect_is(ptr, "externalptr")
  ## Check for no crash:
  rm(ptr)
  gc()
})

test_that("simple commands", {
  skip_if_no_redis()
  ptr <- redis_connect_tcp(REDIS_HOST, REDIS_PORT)

  ans <- redis_command(ptr, list("PING"))
  expect_is(ans, "redis_status")
  expect_output(print(ans), "[Redis: PONG]", fixed = TRUE)
  expect_identical(as.character(ans), "PONG")

  expect_identical(redis_command(ptr, "PING"), ans)
  expect_identical(redis_command(ptr, list("PING", character(0))), ans)

  ## Various invalid commands; some of these need more consistent
  ## errors I think.  Importantly though, none crash.
  expect_error(redis_command(ptr, NULL),
               "Invalid type")
  expect_error(redis_command(ptr, 1L),
               "Invalid type")
  expect_error(redis_command(ptr, list()),
               "argument list cannot be empty")
  expect_error(redis_command(ptr, list(1L)),
               "Redis command must be a non-empty character")
  expect_error(redis_command(ptr, character(0)),
               "Redis command must be a non-empty character")
  expect_error(redis_command(ptr, list(character(0))),
               "Redis command must be a non-empty character")
})

test_that("commands with arguments", {
  skip_if_no_redis()
  ptr <- redis_connect_tcp(REDIS_HOST, REDIS_PORT)
  key <- rand_str()

  expect_equal(redis_command(ptr, list("SET", key, "1")),
               redis_status("OK"))
  expect_equal(redis_command(ptr, list("SET", key, "1")),
               redis_status("OK"))

  expect_equal(redis_command(ptr, list("GET", key)), "1")

  expect_equal(redis_command(ptr, list("DEL", key)), 1)
})

test_that("commands with NULL arguments", {
  skip_if_no_redis()
  ptr <- redis_connect_tcp(REDIS_HOST, REDIS_PORT)
  key <- rand_str()

  expect_equal(redis_command(ptr, list("SET", key, "1", NULL)),
               redis_status("OK"))
  expect_equal(redis_command(ptr, list("SET", key, NULL, "1", NULL)),
               redis_status("OK"))
  expect_equal(redis_command(ptr, list("SET", NULL, key, NULL, "1", NULL)),
               redis_status("OK"))
  expect_equal(redis_command(ptr, list("DEL", key)), 1)
})

test_that("missing values are NULL", {
  skip_if_no_redis()
  ptr <- redis_connect_tcp(REDIS_HOST, REDIS_PORT)
  key <- rand_str(prefix = "redux_")
  expect_null(redis_command(ptr, list("GET", key)))
})

test_that("Errors are converted", {
  skip_if_no_redis()
  ptr <- redis_connect_tcp(REDIS_HOST, REDIS_PORT)
  key <- rand_str(prefix = "redux_")
  on.exit(redis_command(ptr, c("DEL", key)))
  ## Conversion to integer:
  expect_identical(redis_command(ptr, c("LPUSH", key, "a", "b", "c")), 3L)
  expect_error(redis_command(ptr, c("HGET", key, 1)), "WRONGTYPE")
})

## Warning; this pipeline approach is liable to change because we'll
## need to do it slightly differently perhaps.  The main api approach
## would be a *general* codeblock that added commands to a buffer and
## then executed them.  To get that to work we'll need support a
## growing list or pushing them directly into Redis' buffer and
## keeping them protected appropriately.  So for now the automatically
## balanced approach is easiest.
test_that("Pipelining", {
  skip_if_no_redis()
  ptr <- redis_connect_tcp(REDIS_HOST, REDIS_PORT)
  key <- rand_str(prefix = "redux_")
  cmd <- list(list("SET", key, "1"), list("GET", key))
  on.exit(redis_command(ptr, c("DEL", key)))

  x <- redis_pipeline(ptr, cmd)
  expect_equal(length(x), 2)
  expect_equal(x[[1]], redis_status("OK"))
  expect_equal(x[[2]], "1")

  ## A pipeline with an error:
  cmd <- list(c("HGET", key, "a"), c("INCR", key))
  y <- redis_pipeline(ptr, cmd)
  expect_equal(length(x), 2)
  expect_is(y[[1]], "redis_error")
  expect_match(y[[1]], "^WRONGTYPE")
  ## This still ran:
  expect_identical(y[[2]], 2L)
})

## Storing binary data:
test_that("Binary data", {
  skip_if_no_redis()
  ptr <- redis_connect_tcp(REDIS_HOST, REDIS_PORT)
  data <- serialize(1:5, NULL)
  key <- rand_str(prefix = "redux_")
  expect_equal(redis_command(ptr, list("SET", key, data)),
               redis_status("OK"))
  x <- redis_command(ptr, list("GET", key))
  expect_is(x, "raw")
  expect_equal(x, data)

  key2 <- rand_str(prefix = "redux_")
  ok <- redis_command(ptr, list("MSET", key, "1", key2, data))
  expect_equal(ok, redis_status("OK"))

  res <- redis_command(ptr, list("MGET", key, key2))
  expect_equal(res, list("1", data))

  expect_equal(redis_command(ptr, c("DEL", key, key2)), 2L)
})

test_that("Lists of binary data", {
  skip_if_no_redis()
  ptr <- redis_connect_tcp(REDIS_HOST, REDIS_PORT)
  data <- serialize(1:5, NULL)
  key1 <- rand_str(prefix = "redux_")
  key2 <- rand_str(prefix = "redux_")
  cmd <- list("MSET", list(key1, data, key2, data))

  ok <- redis_command(ptr, list("MSET", list(key1, data, key2, data)))
  expect_equal(ok, redis_status("OK"))
  res <- redis_command(ptr, list("MGET", key1, key2))
  expect_equal(res, list(data, data))

  ## But throw an error on a list of lists of lists:
  expect_error(
    redis_command(ptr, list("MSET", list(key1, data, key2, list(data)))),
    "Nested list element")
  expect_error(
    redis_command(ptr, list("MSET", list(list(key1), data, key2, data))),
    "Nested list element")

  redis_command(ptr, list("DEL", list(key1, key2)))
})

test_that("pointer commands are safe", {
  skip_if_no_redis()
  expect_error(redis_command(NULL, "PING"),
               "Expected an external pointer")
  expect_error(redis_command(list(), "PING"),
               "Expected an external pointer")
  ptr <- redis_connect_tcp(REDIS_HOST, REDIS_PORT)
  expect_error(redis_command(list(ptr), "PING"),
               "Expected an external pointer")

  expect_equal(redis_command(ptr, "PING"),
               redis_status("PONG"))

  ptr_null <- unserialize(serialize(ptr, NULL))
  expect_error(redis_command(ptr_null, "PING"),
               "Context is not connected")
})
