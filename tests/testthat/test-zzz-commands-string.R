context("commands - string")

test_that("APPEND", {
  skip_if_cmd_unsupported("APPEND")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  expect_equal(con$APPEND(key, "hello"), 5L)
  expect_equal(con$APPEND(key, " world"), 11L)
  expect_equal(con$GET(key), "hello world")
})

test_that("BITCOUNT", {
  skip_if_cmd_unsupported("BITCOUNT")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SET(key, "foobar")
  expect_equal(con$BITCOUNT(key), 26L)
  expect_equal(con$BITCOUNT(key, 0, 0), 4L)
  expect_equal(con$BITCOUNT(key, 1, 1), 6L)
})

test_that("BITFIELD:prep", {
  key <- rand_str()
  ans <- redis_cmds$BITFIELD(key, INCRBY = c("i5", "100", "1"),
                             GET = c("u4", "0"))
  expect_equal(ans, list("BITFIELD", key,
                         list("GET", c("u4", "0")),
                         NULL,
                         list("INCRBY", c("i5", "100", "1")),
                         NULL))
})

test_that("BITFIELD:run", {
  skip_if_cmd_unsupported("BITFIELD")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  ans <- con$BITFIELD(key, INCRBY = c("i5", "100", "1"), GET = c("u4", "0"))

  expect_equal(ans, list(0, 1))
})


test_that("BITCOUNT", {
  skip_if_cmd_unsupported("BITCOUNT")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SET(key, "foobar")
  expect_equal(con$BITCOUNT(key), 26)
  expect_equal(con$BITCOUNT(key, 0, 0), 4)
  expect_equal(con$BITCOUNT(key, 1, 1), 6)
})

test_that("BITOP", {
  skip_if_cmd_unsupported("BITOP")
  con <- test_hiredis_connection()
  key1 <- rand_str()
  key2 <- rand_str()
  dest <- rand_str()
  on.exit(con$DEL(c(key1, key2, dest)))

  con$SET(key1, "foobar")
  con$SET(key2, "abcdef")

  expect_equal(con$BITOP("AND", dest, c(key1, key2)), 6)
  expect_equal(con$GET(dest), "`bc`ab")
})

test_that("BITPOS", {
  skip_if_cmd_unsupported("BITPOS")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SET(key, as.raw(c(255, 240, 0)))
  expect_equal(con$BITPOS(key, 0), 12)
  con$SET(key, as.raw(c(0, 255, 240)))
  expect_equal(con$BITPOS(key, 1, 0), 8)
  expect_equal(con$BITPOS(key, 1, 2), 16)
  con$SET(key, as.raw(c(0, 0, 0)))
  expect_equal(con$BITPOS(key, 1), -1)
})

test_that("DECR", {
  skip_if_cmd_unsupported("DECR")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SET(key, 10)
  expect_equal(con$DECR(key), 9L)

  con$SET(key, "234293482390480948029348230948")
  expect_error(con$DECR(key), "out of range")
})

test_that("DECRBY", {
  skip_if_cmd_unsupported("DECRBY")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SET(key, 10)
  expect_equal(con$DECRBY(key, 3), 7L)
})

test_that("GET", {
  skip_if_cmd_unsupported("GET")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  expect_null(con$GET(key))
  con$SET(key, "Hello")
  expect_equal(con$GET(key), "Hello")
})

test_that("GETBIT", {
  skip_if_cmd_unsupported("GETBIT")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  expect_equal(con$SETBIT(key, 7, 1), 0)
  expect_equal(con$GETBIT(key, 0), 0)
  expect_equal(con$GETBIT(key, 7), 1)
  expect_equal(con$GETBIT(key, 100), 0)
})

test_that("GETRANGE", {
  skip_if_cmd_unsupported("GETRANGE")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SET(key, "This is a string")
  expect_equal(con$GETRANGE(key, 0, 3), "This")
  expect_equal(con$GETRANGE(key, -3, -1), "ing")
  expect_equal(con$GETRANGE(key, 0, -1), "This is a string")
  expect_equal(con$GETRANGE(key, 10, 100), "string")
})

test_that("GETSET", {
  skip_if_cmd_unsupported("GETSET")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SET(key, "Hello")
  expect_equal(con$GETSET(key, "World"), "Hello")
  expect_equal(con$GET(key), "World")
})

test_that("INCR", {
  skip_if_cmd_unsupported("INCR")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SET(key, 10)
  expect_equal(con$INCR(key), 11L)
  expect_equal(con$GET(key), "11")
})

test_that("INCRBY", {
  skip_if_cmd_unsupported("INCRBY")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SET(key, 10)
  expect_equal(con$INCRBY(key, 5), 15L)
  expect_equal(con$GET(key), "15")
})

test_that("INCRBYFLOAT", {
  skip_if_cmd_unsupported("INCRBYFLOAT")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SET(key, 10.50)
  expect_equal(con$INCRBYFLOAT(key, 0.1), "10.6")
  expect_equal(con$INCRBYFLOAT(key, -5), "5.6")
  con$SET(key, "5.0e3")
  expect_equal(con$INCRBYFLOAT(key, "2.0e2"), "5200")
})

test_that("MGET", {
  skip_if_cmd_unsupported("MGET")
  con <- test_hiredis_connection()
  key1 <- rand_str()
  key2 <- rand_str()
  on.exit(con$DEL(c(key1, key2)))

  con$SET(key1, "Hello")
  con$SET(key2, "World")
  expect_equal(con$MGET(c(key1, key2)), list("Hello", "World"))
})

test_that("MSET", {
  skip_if_cmd_unsupported("MSET")
  con <- test_hiredis_connection()
  key1 <- rand_str()
  key2 <- rand_str()
  on.exit(con$DEL(c(key1, key2)))

  con$MSET(c(key1, key2), c("Hello", "World"))
  expect_equal(con$GET(key1), "Hello")
  expect_equal(con$GET(key2), "World")
})

test_that("MSETNX", {
  skip_if_cmd_unsupported("MSETNX")
  con <- test_hiredis_connection()
  key1 <- rand_str()
  key2 <- rand_str()
  key3 <- rand_str()
  on.exit(con$DEL(c(key1, key2, key3)))

  expect_equal(con$MSETNX(c(key1, key2), c("Hello", "there")), 1L)
  expect_equal(con$MSETNX(c(key2, key3), c("there", "world")), 0L)
  expect_equal(con$MGET(c(key1, key2, key3)), list("Hello", "there", NULL))
})

test_that("PSETEX", {
  skip_if_cmd_unsupported("PSETEX")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$PSETEX(key, 1000, "Hello")
  expect_is(con$PTTL(key), "integer")
  expect_equal(con$GET(key), "Hello")
})

## TODO: there is more complex behaviour here with timeouts that could
## be tested.
test_that("SET", {
  skip_if_cmd_unsupported("SET")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SET(key, "Hello")
  expect_equal(con$GET(key), "Hello")
})

test_that("SETBIT", {
  skip_if_cmd_unsupported("SETBIT")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  expect_equal(con$SETBIT(key, 7, 1), 0)
  expect_equal(con$SETBIT(key, 7, 0), 1)
  expect_equal(con$GET(key), as.raw(0))
})

test_that("SETEX", {
  skip_if_cmd_unsupported("SETEX")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SETEX(key, 10, "hello")
  expect_is(con$TTL(key), "integer")
  expect_equal(con$GET(key), "hello")
})

test_that("SETNX", {
  skip_if_cmd_unsupported("SETNX")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  expect_equal(con$SETNX(key, "Hello"), 1)
  expect_equal(con$SETNX(key, "World"), 0)
  expect_equal(con$GET(key), "Hello")
})

test_that("SETRANGE", {
  skip_if_cmd_unsupported("SETRANGE")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SET(key, "Hello world")
  con$SETRANGE(key, 6, "Redis")
  expect_equal(con$GET(key), "Hello Redis")
  con$DEL(key)

  con$SETRANGE(key, 6, "Redis")
  expect_equal(con$GET(key),
               c(rep(as.raw(0), 6), charToRaw("Redis")))
})

test_that("STRLEN", {
  skip_if_cmd_unsupported("STRLEN")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SET(key, "Hello world")
  expect_equal(con$STRLEN(key), 11)
  expect_equal(con$STRLEN("nonexisting"), 0)
})
