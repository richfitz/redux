context("commands - list")

test_that("BLPOP", {
  skip_if_cmd_unsupported("BLPOP")
  con <- test_hiredis_connection()
  key1 <- rand_str()
  key2 <- rand_str()
  on.exit(con$DEL(c(key1, key2)))

  con$RPUSH(key1, letters[1:3])
  res <- con$BLPOP(c(key1, key2), 0)
  expect_equal(res, list(key1, "a"))
})

test_that("BRPOP", {
  skip_if_cmd_unsupported("BRPOP")
  con <- test_hiredis_connection()
  key1 <- rand_str()
  key2 <- rand_str()
  on.exit(con$DEL(c(key1, key2)))

  con$RPUSH(key1, letters[1:3])
  res <- con$BRPOP(c(key1, key2), 0)
  expect_equal(res, list(key1, "c"))
})

test_that("BRPOPLPUSH", {
  skip_if_cmd_unsupported("BRPOPLPUSH")
  con <- test_hiredis_connection()
  key1 <- rand_str()
  key2 <- rand_str()
  on.exit(con$DEL(c(key1, key2)))

  con$RPUSH(key1, "one")
  con$RPUSH(key1, "two")
  con$RPUSH(key1, "three")
  expect_equal(con$BRPOPLPUSH(key1, key2, 100), "three")
  expect_equal(con$LRANGE(key1, 0, -1), list("one", "two"))
  expect_equal(con$LRANGE(key2, 0, -1), list("three"))
})

test_that("LINDEX", {
  skip_if_cmd_unsupported("LINDEX")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$LPUSH(key, "World")
  con$LPUSH(key, "Hello")
  expect_equal(con$LINDEX(key, 0), "Hello")
  expect_equal(con$LINDEX(key, -1), "World")
  expect_null(con$LINDEX(key, 3), "World")
})

test_that("LINSERT", {
  skip_if_cmd_unsupported("LINSERT")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$RPUSH(key, "Hello")
  con$RPUSH(key, "World")
  expect_equal(con$LINSERT(key, "BEFORE", "World", "There"), 3)
  expect_equal(con$LRANGE(key, 0, -1),
               list("Hello", "There", "World"))
})

test_that("LLEN", {
  skip_if_cmd_unsupported("LLEN")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$LPUSH(key, "World")
  con$LPUSH(key, "Hello")
  expect_equal(con$LLEN(key), 2L)
})

test_that("LPOP", {
  skip_if_cmd_unsupported("LPOP")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$RPUSH(key, "one")
  con$RPUSH(key, "two")
  con$RPUSH(key, "three")
  expect_equal(con$LPOP(key), "one")
  expect_equal(con$LRANGE(key, 0, -1), list("two", "three"))
})

test_that("LPUSH", {
  skip_if_cmd_unsupported("LPUSH")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  expect_equal(con$LPUSH(key, "world"), 1)
  expect_equal(con$LPUSH(key, "hello"), 2)
  expect_equal(con$LRANGE(key, 0, -1), list("hello", "world"))
})

test_that("LPUSHX", {
  skip_if_cmd_unsupported("LPUSHX")
  con <- test_hiredis_connection()
  key1 <- rand_str()
  key2 <- rand_str()
  on.exit(con$DEL(c(key1, key2)))

  expect_equal(con$LPUSH(key1, "World"), 1)
  expect_equal(con$LPUSHX(key1, "Hello"), 2)
  expect_equal(con$LPUSHX(key2, "Hello"), 0)
  expect_equal(con$LRANGE(key1, 0, -1), list("Hello", "World"))
  expect_equal(con$LRANGE(key2, 0, -1), list())
})

test_that("LRANGE", {
  skip_if_cmd_unsupported("LRANGE")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$RPUSH(key, "one")
  con$RPUSH(key, "two")
  con$RPUSH(key, "three")
  expect_equal(con$LRANGE(key, 0, 0), list("one"))
  expect_equal(con$LRANGE(key, -3, 2), list("one", "two", "three"))
  expect_equal(con$LRANGE(key, -100, 100), list("one", "two", "three"))
  expect_equal(con$LRANGE(key, 5, 10), list())
})

test_that("LREM", {
  skip_if_cmd_unsupported("LREM")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$RPUSH(key, "hello")
  con$RPUSH(key, "hello")
  con$RPUSH(key, "foo")
  con$RPUSH(key, "hello")
  expect_equal(con$LREM(key, -2, "hello"), 2)
  expect_equal(con$LRANGE(key, 0, -1), list("hello", "foo"))
})

test_that("LSET", {
  skip_if_cmd_unsupported("LSET")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$RPUSH(key, "one")
  con$RPUSH(key, "two")
  con$RPUSH(key, "three")
  con$LSET(key, 0, "four")
  con$LSET(key, -2, "five")
  expect_equal(con$LRANGE(key, 0, -1), list("four", "five", "three"))
})

test_that("LTRIM", {
  skip_if_cmd_unsupported("LTRIM")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$RPUSH(key, "one")
  con$RPUSH(key, "two")
  con$RPUSH(key, "three")
  con$LTRIM(key, 1, -1)
  expect_equal(con$LRANGE(key, 0, -1), list("two", "three"))
})

test_that("RPOP", {
  skip_if_cmd_unsupported("RPOP")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$RPUSH(key, "one")
  con$RPUSH(key, "two")
  con$RPUSH(key, "three")
  expect_equal(con$RPOP(key), "three")
  expect_equal(con$LRANGE(key, 0, -1), list("one", "two"))
})

test_that("RPOPLPUSH", {
  skip_if_cmd_unsupported("RPOPLPUSH")
  con <- test_hiredis_connection()
  key1 <- rand_str()
  key2 <- rand_str()
  on.exit(con$DEL(c(key1, key2)))

  con$RPUSH(key1, "one")
  con$RPUSH(key1, "two")
  con$RPUSH(key1, "three")
  expect_equal(con$RPOPLPUSH(key1, key2), "three")
  expect_equal(con$LRANGE(key1, 0, -1), list("one", "two"))
  expect_equal(con$LRANGE(key2, 0, -1), list("three"))
})

test_that("RPUSH", {
  skip_if_cmd_unsupported("RPUSH")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  expect_equal(con$RPUSH(key, "hello"), 1L)
  expect_equal(con$RPUSH(key, "world"), 2L)
  expect_equal(con$LRANGE(key, 0, -1), list("hello", "world"))
})

test_that("RPUSHX", {
  skip_if_cmd_unsupported("RPUSHX")
  con <- test_hiredis_connection()
  key1 <- rand_str()
  key2 <- rand_str()
  on.exit(con$DEL(c(key1, key2)))

  expect_equal(con$RPUSH(key1, "hello"), 1L)
  expect_equal(con$RPUSHX(key1, "world"), 2L)
  expect_equal(con$RPUSHX(key2, "world"), 0L)
  expect_equal(con$LRANGE(key1, 0, -1), list("hello", "world"))
  expect_equal(con$LRANGE(key2, 0, -1), list())
})
