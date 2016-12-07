context("commands - ")

test_that("HDEL", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  expect_equal(con$HSET(key, "field1", "foo"), 1)
  expect_equal(con$HDEL(key, "field1"), 1)
  expect_equal(con$HDEL(key, "field1"), 0)
})

test_that("HEXISTS", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  expect_equal(con$HSET(key, "field1", "foo"), 1)
  expect_equal(con$HEXISTS(key, "field1"), 1)
  expect_equal(con$HEXISTS(key, "field2"), 0)
})

test_that("HGET", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  expect_equal(con$HSET(key, "field1", "foo"), 1)
  expect_equal(con$HGET(key, "field1"), "foo")
  expect_null(con$HGET(key, "field2"))
})

test_that("HGETALL", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  expect_equal(con$HSET(key, "field1", "Hello"), 1)
  expect_equal(con$HSET(key, "field2", "World"), 1)
  dat <- con$HGETALL(key)
  expect_is(dat, "list")
  expect_equal(length(dat), 4L)
  dat <- matrix(vcapply(dat, identity), 2)
  i <- match(c("field1", "field2"), dat[1, ])
  expect_equal(dat[2, i], c("Hello", "World"))
})

test_that("HINCRBY", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$HSET(key, "field", 5)
  expect_equal(con$HINCRBY(key, "field", 1), 6)
  expect_equal(con$HINCRBY(key, "field", -1), 5)
  expect_equal(con$HINCRBY(key, "field", -10), -5)
})

test_that("HINCRBYFLOAT", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$HSET(key, "field", 10.50)
  expect_equal(con$HINCRBYFLOAT(key, "field", 0.1), "10.6")
  expect_equal(con$HINCRBYFLOAT(key, "field", -5), "5.6")
  con$HSET(key, "field", "5.0e3")
  expect_equal(con$HINCRBYFLOAT(key, "field", "2.0e2"), "5200")
})

test_that("HKEYS", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$HSET(key, "field1", "Hello")
  con$HSET(key, "field2", "World")
  expect_equal(sort(unlist(con$HKEYS(key))), sort(c("field1", "field2")))
})

test_that("HLEN", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$HSET(key, "field1", "Hello")
  con$HSET(key, "field2", "World")
  expect_equal(con$HLEN(key), 2L)
})

test_that("HMGET", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$HSET(key, "field1", "Hello")
  con$HSET(key, "field2", "World")
  expect_equal(con$HMGET(key, c("field1", "field2", "nofield")),
               list("Hello", "World", NULL))
})

test_that("HMSET", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$HMSET(key, c("field1", "field2"), c("Hello", "World"))
  expect_equal(con$HGET(key, "field1"), "Hello")
  expect_equal(con$HGET(key, "field2"), "World")
})

test_that("HSET", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$HSET(key, "field1", "Hello")
  expect_equal(con$HGET(key, "field1"), "Hello")
})


test_that("HSETNX", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$HSETNX(key, "field1", "Hello")
  con$HSETNX(key, "field1", "World")
  expect_equal(con$HGET(key, "field1"), "Hello")
})

test_that("HVALS", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$HSET(key, "field1", "Hello")
  con$HSET(key, "field2", "World")
  expect_equal(con$HVALS(key), list("Hello", "World"))
})

## HSCAN in scan testing
