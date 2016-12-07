context("commands - generic")

test_that("DEL", {
  skip_if_no_redis()
  con <- hiredis()
  key1 <- rand_str()
  key2 <- rand_str()
  on.exit(con$DEL(c(key1, key2)))
  con$SET(key1, "Hello")
  con$SET(key2, "World")
  expect_equal(con$DEL(c(key1, key2, rand_str())), 2L)
})

test_that("DUMP", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SET(key, 10)
  expect_is(con$DUMP(key), "raw")
})

test_that("EXISTS", {
  skip_if_no_redis()
  con <- hiredis()
  key1 <- rand_str()
  key2 <- rand_str()
  key3 <- rand_str()
  on.exit(con$DEL(c(key1, key2)))

  con$SET(key1, "Hello")
  expect_equal(con$EXISTS(key1), 1)
  expect_equal(con$EXISTS(key3), 0)
  con$SET(key2, "Hello")
  expect_equal(con$EXISTS(c(key1, key2, key3)), 2)
})

test_that("EXPIRE", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SET(key, "Hello")
  con$EXPIRE(key, 10)
  expect_gt(con$TTL(key), 9)
  con$SET(key, "Hello world")
  expect_equal(con$TTL(key), -1)
})

test_that("EXPIRE", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SET(key, "Hello")
  expect_equal(con$EXISTS(key), 1)
  expect_equal(con$EXPIREAT(key, 1293840000), 1)
  expect_equal(con$EXISTS(key), 0)
})

test_that("KEYS", {
  skip_if_no_redis()
  skip_if_not_isolated_redis()
  con <- hiredis()
  con$FLUSHDB()
  on.exit(con$DEL(c("one", "two", "three", "four")))
  con$MSET(c("one", "two", "three", "four"), 1:4)

  tmp <- con$KEYS("*o*")
  expect_equal(sort(vcapply(tmp, identity, USE.NAMES = FALSE)),
               sort(c("one", "two", "four")))

  expect_equal(con$KEYS("t??"), list("two"))

  tmp <- con$KEYS("*")
  expect_equal(sort(vcapply(tmp, identity, USE.NAMES = FALSE)),
               sort(c("one", "two", "three", "four")))
})

test_that("MOVE", {
  skip_if_no_redis()
  con0 <- hiredis()
  con1 <- hiredis(redis_config(db = 1))
  key <- rand_str()
  on.exit({
    con0$DEL(key)
    con1$DEL(key)
  })

  con0$SET(key, "hello")
  expect_equal(con0$MOVE(key, 1), 1)
  expect_equal(con0$EXISTS(key), 0)
  expect_equal(con1$EXISTS(key), 1)
})

test_that("OBJECT", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$LPUSH(key, "Hello world")
  expect_equal(con$OBJECT("refcount", key), 1)
  expect_equal(con$OBJECT("encoding", key), "ziplist")
  expect_is(con$OBJECT("idletime", key), "integer")
})

test_that("PERSIST", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SET(key, "Hello")
  con$EXPIRE(key, 10)
  expect_gt(con$TTL(key), 0)
  expect_equal(con$PERSIST(key), 1)
  expect_equal(con$TTL(key), -1)
})

test_that("PEXPIRE", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SET(key, "Hello")
  expect_equal(con$PEXPIRE(key, 1500), 1)
  expect_gt(con$TTL(key), 0)
  expect_gt(con$PTTL(key), 0)
})

test_that("PEXPIREAT", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SET(key, "Hello")
  expect_equal(con$PEXPIREAT(key, 1555555555005), 1)
  expect_gt(con$TTL(key), 0)
  expect_gt(con$PTTL(key), 0)
})

test_that("PTTL", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SET(key, "Hello")
  expect_equal(con$EXPIRE(key, 1), 1)
  expect_gt(con$PTTL(key), 100)
})

test_that("RANDOMKEY", {
  skip_if_no_redis()
  skip_if_not_isolated_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$FLUSHDB()
  con$SET(key, "hello")
  expect_equal(con$RANDOMKEY(), key)
  con$FLUSHDB()
  expect_null(con$RANDOMKEY())
})

test_that("RENAME", {
  skip_if_no_redis()
  con <- hiredis()
  key1 <- rand_str()
  key2 <- rand_str()
  on.exit(con$DEL(c(key1, key2)))

  con$SET(key1, "Hello")
  con$RENAME(key1, key2)
  expect_equal(con$GET(key2), "Hello")
})

test_that("RENAMENX", {
  skip_if_no_redis()
  con <- hiredis()
  key1 <- rand_str()
  key2 <- rand_str()
  on.exit(con$DEL(c(key1, key2)))

  con$SET(key1, "Hello")
  con$SET(key2, "World")
  con$RENAMENX(key1, key2)
  expect_equal(con$GET(key2), "World")
})

test_that("RESTORE", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  dat <- as.raw(c(0x0a, 0x11, 0x11, 0x00, 0x00, 0x00, 0x0e, 0x00, 0x00,
                  0x00, 0x03, 0x00, 0x00, 0xf2, 0x02, 0xf3, 0x02, 0xf4,
                  0xff, 0x06, 0x00, 0x5a, 0x31, 0x5f, 0x1c, 0x67, 0x04,
                  0x21, 0x18))
  con$RESTORE(key, 0, dat)
  expect_equal(con$TYPE(key), redis_status("list"))
  expect_equal(con$LRANGE(key, 0, -1), list("1", "2", "3"))
})

test_that("TTL", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SET(key, "Hello")
  con$EXPIRE(key, 10)
  expect_gt(con$TTL(key), 0)
})

test_that("TYPE", {
  skip_if_no_redis()
  con <- hiredis()
  key1 <- rand_str()
  key2 <- rand_str()
  key3 <- rand_str()
  on.exit(con$DEL(c(key1, key2, key3)))

  con$SET(key1, "value")
  con$LPUSH(key2, "value")
  con$SADD(key3, "value")
  expect_equal(con$TYPE(key1), redis_status("string"))
  expect_equal(con$TYPE(key2), redis_status("list"))
  expect_equal(con$TYPE(key3), redis_status("set"))
})

test_that("WAIT", {
  skip("not sure if will keep")
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SET(key, "bar")
  con$WAIT(1, 0)
  con$WAIT(2, 1000)
})

## NOTE: not testing MIGRATE
## NOTE: not testing SCAN as tested extensively elsewhere
## NOTE: not testing SORT as tested elsewhere
## NOTE: not testing TOUCH as it's in too recent redis
## NOTE: not testing WAIT as it locks up R in non-clustered Redis
