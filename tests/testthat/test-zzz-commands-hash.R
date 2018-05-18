context("commands - hash")

test_that("HDEL", {
  skip_if_cmd_unsupported("HDEL")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  expect_equal(con$HSET(key, "field1", "foo"), 1)
  expect_equal(con$HDEL(key, "field1"), 1)
  expect_equal(con$HDEL(key, "field1"), 0)
})

test_that("HEXISTS", {
  skip_if_cmd_unsupported("HEXISTS")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  expect_equal(con$HSET(key, "field1", "foo"), 1)
  expect_equal(con$HEXISTS(key, "field1"), 1)
  expect_equal(con$HEXISTS(key, "field2"), 0)
})

test_that("HGET", {
  skip_if_cmd_unsupported("HGET")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  expect_equal(con$HSET(key, "field1", "foo"), 1)
  expect_equal(con$HGET(key, "field1"), "foo")
  expect_null(con$HGET(key, "field2"))
})

test_that("HGETALL", {
  skip_if_cmd_unsupported("HGETALL")
  con <- test_hiredis_connection()
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
  skip_if_cmd_unsupported("HINCRBY")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$HSET(key, "field", 5)
  expect_equal(con$HINCRBY(key, "field", 1), 6)
  expect_equal(con$HINCRBY(key, "field", -1), 5)
  expect_equal(con$HINCRBY(key, "field", -10), -5)
})

test_that("HINCRBYFLOAT", {
  skip_if_cmd_unsupported("HINCRBYFLOAT")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$HSET(key, "field", 10.50)
  expect_equal(con$HINCRBYFLOAT(key, "field", 0.1), "10.6")
  expect_equal(con$HINCRBYFLOAT(key, "field", -5), "5.6")
  con$HSET(key, "field", "5.0e3")
  expect_equal(con$HINCRBYFLOAT(key, "field", "2.0e2"), "5200")
})

test_that("HKEYS", {
  skip_if_cmd_unsupported("HKEYS")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$HSET(key, "field1", "Hello")
  con$HSET(key, "field2", "World")
  expect_equal(sort(unlist(con$HKEYS(key))), sort(c("field1", "field2")))
})

test_that("HLEN", {
  skip_if_cmd_unsupported("HLEN")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$HSET(key, "field1", "Hello")
  con$HSET(key, "field2", "World")
  expect_equal(con$HLEN(key), 2L)
})

test_that("HMGET", {
  skip_if_cmd_unsupported("HMGET")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$HSET(key, "field1", "Hello")
  con$HSET(key, "field2", "World")
  expect_equal(con$HMGET(key, c("field1", "field2", "nofield")),
               list("Hello", "World", NULL))
})

test_that("HMSET", {
  skip_if_cmd_unsupported("HMSET")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$HMSET(key, c("field1", "field2"), c("Hello", "World"))
  expect_equal(con$HGET(key, "field1"), "Hello")
  expect_equal(con$HGET(key, "field2"), "World")
})

test_that("HSET", {
  skip_if_cmd_unsupported("HSET")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$HSET(key, "field1", "Hello")
  expect_equal(con$HGET(key, "field1"), "Hello")
})

test_that("HSETNX", {
  skip_if_cmd_unsupported("HSETNX")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$HSETNX(key, "field1", "Hello")
  con$HSETNX(key, "field1", "World")
  expect_equal(con$HGET(key, "field1"), "Hello")
})

test_that("HSTRLEN:prep", {
  key <- rand_str()
  expect_equal(redis_cmds$HSTRLEN(key, "f1"),
               list("HSTRLEN", key, "f1"))
})

test_that("HSTRLEN:run", {
  skip_if_cmd_unsupported("HSTRLEN")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$HMSET(key, c("f1", "f2", "f3"), c("HelloWorld", "99", "-256"))
  expect_equal(con$HSTRLEN(key, "f1"), 10)
  expect_equal(con$HSTRLEN(key, "f2"), 2)
  expect_equal(con$HSTRLEN(key, "f3"), 4)
})

test_that("HVALS", {
  skip_if_cmd_unsupported("HVALS")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$HSET(key, "field1", "Hello")
  con$HSET(key, "field2", "World")
  expect_equal(con$HVALS(key), list("Hello", "World"))
})
