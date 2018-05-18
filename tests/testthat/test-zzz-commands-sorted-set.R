context("commands - sorted set")

test_that("ZADD", {
  skip_if_cmd_unsupported("ZADD")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  ## I have generated invalid code for the ZADD bits of code...

  expect_equal(con$ZADD(key, 1, "one"), 1)
  expect_equal(con$ZADD(key, 1, "uno"), 1)
  expect_equal(con$ZADD(key, c(2, 3), c("two", "three")), 2)
  expect_equal(con$ZRANGE(key, 0, -1, "WITHSCORES"),
               list("one", "1", "uno", "1",
                    "two", "2", "three", "3"))
})

test_that("ZCARD", {
  skip_if_cmd_unsupported("ZCARD")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$ZADD(key, 1, "one")
  con$ZADD(key, 2, "two")
  expect_equal(con$ZCARD(key), 2)
})

test_that("ZCOUNT", {
  skip_if_cmd_unsupported("ZCOUNT")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$ZADD(key, 1, "one")
  con$ZADD(key, 2, "two")
  con$ZADD(key, 3, "three")
  expect_equal(con$ZCOUNT(key, "-inf", "+inf"), 3)
  expect_equal(con$ZCOUNT(key, "(1", 3), 2)
})

test_that("ZINCRBY", {
  skip_if_cmd_unsupported("ZINCRBY")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$ZADD(key, 1, "one")
  con$ZADD(key, 2, "two")
  expect_equal(con$ZINCRBY(key, 2, "one"), "3")
  ## TODO: this would be nicer as WITHSCORES = TRUE I think.  It's
  ## probably worth thinking what other commands this impacts while
  ## running the code generation.
  ##
  ## The big issue is that for migrate (at least) there was a change
  ## where key moved from being a single enum to being an enum that
  ## would take either 'key' or '""'; will want to comb through
  ## previous versions of the json and make sure I do the right thing
  ## here.
  ## * GEORADIUS: withcoord, withdist, withhash
  ## * GEORADIUSBYMEMBER: withcoord, withdist, withhash
  ## * MIGRATE: copy, replace
  ## * RESTORE: replace
  ## * SORT: sorting
  ## * ZADD: change, increment
  ## * ZRANGE: withscores
  ## * ZRANGEBYSCORE: withscores
  ## * ZREVRANGE: withscores
  ## * ZREVRANGEBYSCORE: withscores
  expect_equal(con$ZRANGE(key, 0, -1, "WITHSCORES"),
               list("two", "2", "one", "3"))
})

test_that("ZINTERSTORE", {
  skip_if_cmd_unsupported("ZINTERSTORE")
  con <- test_hiredis_connection()
  key1 <- rand_str()
  key2 <- rand_str()
  key3 <- rand_str()
  on.exit(con$DEL(c(key1, key2, key3)))

  con$ZADD(key1, 1, "one")
  con$ZADD(key1, 2, "two")
  con$ZADD(key2, 1, "one")
  con$ZADD(key2, 2, "two")
  con$ZADD(key2, 3, "three")
  expect_equal(con$ZINTERSTORE(key3, 2, c(key1, key2), c(2, 3)), 2)
  expect_equal(con$ZRANGE(key3, 0, -1, "WITHSCORES"),
               list("one", "5", "two", "10"))
})

test_that("ZLEXCOUNT", {
  skip_if_cmd_unsupported("ZLEXCOUNT")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$ZADD(key,
           c(0,   0,   0,   0,   0),
           c("a", "b", "c", "d", "e"))
  con$ZADD(key, c(0, 0), c("f", "g"))
  expect_equal(con$ZLEXCOUNT(key, "-", "+"), 7L)
  expect_equal(con$ZLEXCOUNT(key, "[b", "[f"), 5L)
})

test_that("ZRANGE", {
  skip_if_cmd_unsupported("ZRANGE")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))
  con$ZADD(key, 1, "one")
  con$ZADD(key, 2, "two")
  con$ZADD(key, 3, "three")
  expect_equal(con$ZRANGE(key, 0, -1), list("one", "two", "three"))
  expect_equal(con$ZRANGE(key, 2, 3), list("three"))
  expect_equal(con$ZRANGE(key, -2, -1), list("two", "three"))
  expect_equal(con$ZRANGE(key, 0, 1, "WITHSCORES"),
               list("one", "1", "two", "2"))
})

test_that("ZRANGEBYLEX", {
  skip_if_cmd_unsupported("ZRANGEBYLEX")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$ZADD(key,
           c(0,   0,   0,   0,   0,   0,   0),
           c("a", "b", "c", "d", "e", "f", "g"))
  expect_equal(con$ZRANGEBYLEX(key, "-", "[c"),
               list("a", "b", "c"))
  expect_equal(con$ZRANGEBYLEX(key, "-", "(c"),
               list("a", "b"))
  expect_equal(con$ZRANGEBYLEX(key, "[aaa", "(g"),
               list("b", "c", "d", "e", "f"))
})

test_that("ZREVRANGEBYLEX", {
  skip_if_cmd_unsupported("ZREVRANGEBYLEX")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$ZADD(key,
           c(0,   0,   0,   0,   0,   0,   0),
           c("a", "b", "c", "d", "e", "f", "g"))
  expect_equal(con$ZREVRANGEBYLEX(key, "[c", "-"),
               list("c", "b", "a"))
  expect_equal(con$ZREVRANGEBYLEX(key, "(c", "-"),
               list("b", "a"))
  expect_equal(con$ZREVRANGEBYLEX(key, "(g", "[aaa"),
               list("f", "e", "d", "c", "b"))
})

test_that("ZRANGEBYSCORE", {
  skip_if_cmd_unsupported("ZRANGEBYSCORE")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$ZADD(key, 1, "one")
  con$ZADD(key, 2, "two")
  con$ZADD(key, 3, "three")

  expect_equal(con$ZRANGEBYSCORE(key, "-inf", "+inf"),
               list("one", "two", "three"))
  expect_equal(con$ZRANGEBYSCORE(key, "1", "2"), list("one", "two"))
  expect_equal(con$ZRANGEBYSCORE(key, "(1", "2"), list("two"))
  expect_equal(con$ZRANGEBYSCORE(key, "(1", "(2"), list())
})

test_that("ZRANK", {
  skip_if_cmd_unsupported("ZRANK")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$ZADD(key, 1, "one")
  con$ZADD(key, 2, "two")
  con$ZADD(key, 3, "three")
  expect_equal(con$ZRANK(key, "three"), 2L)
  expect_null(con$ZRANK(key, "four"))
})

test_that("ZREM", {
  skip_if_cmd_unsupported("ZREM")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$ZADD(key, 1, "one")
  con$ZADD(key, 2, "two")
  con$ZADD(key, 3, "three")

  expect_equal(con$ZREM(key, "two"), 1)
  expect_equal(con$ZRANGE(key, 0, -1, "WITHSCORES"),
               list("one", "1", "three", "3"))
})

test_that("ZREMRANGEBYLEX", {
  skip_if_cmd_unsupported("ZREMRANGEBYLEX")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$ZADD(key, c(0, 0, 0, 0, 0), c("aaaa", "b", "c", "d", "e"))
  con$ZADD(key, c(0, 0, 0, 0, 0), c("foo", "zap", "zip", "ALPHA", "alpha"))
  expect_equal(con$ZRANGE(key, 0, -1),
               list("ALPHA", "aaaa", "alpha", "b", "c", "d", "e",
                    "foo", "zap", "zip"))

  expect_equal(con$ZREMRANGEBYLEX(key, "[alpha", "[omega"), 6)
  expect_equal(con$ZRANGE(key, 0, -1),
               list("ALPHA", "aaaa", "zap", "zip"))
})

test_that("ZREMRANGEBYRANK", {
  skip_if_cmd_unsupported("ZREMRANGEBYRANK")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$ZADD(key, 1, "one")
  con$ZADD(key, 2, "two")
  con$ZADD(key, 3, "three")

  expect_equal(con$ZREMRANGEBYRANK(key, 0, 1), 2)
  expect_equal(con$ZRANGE(key, 0, -1, "WITHSCORES"),
               list("three", "3"))
})

test_that("ZREMRANGEBYSCORE", {
  skip_if_cmd_unsupported("ZREMRANGEBYSCORE")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$ZADD(key, 1, "one")
  con$ZADD(key, 2, "two")
  con$ZADD(key, 3, "three")

  expect_equal(con$ZREMRANGEBYSCORE(key, "-inf", "(2"), 1)
  expect_equal(con$ZRANGE(key, 0, -1, "WITHSCORES"),
               list("two", "2", "three", "3"))
})

test_that("ZREVRANGE", {
  skip_if_cmd_unsupported("ZREVRANGE")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$ZADD(key, 1, "one")
  con$ZADD(key, 2, "two")
  con$ZADD(key, 3, "three")

  expect_equal(con$ZREVRANGE(key, 0, -1),
               list("three", "two", "one"))
  expect_equal(con$ZREVRANGE(key, 2, 3),
               list("one"))
  expect_equal(con$ZREVRANGE(key, -2, -1),
               list("two", "one"))
})

test_that("ZREVRANGEBYSCORE", {
  skip_if_cmd_unsupported("ZREVRANGEBYSCORE")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$ZADD(key, 1, "one")
  con$ZADD(key, 2, "two")
  con$ZADD(key, 3, "three")

  expect_equal(con$ZREVRANGEBYSCORE(key, "+inf", "-inf"),
               list("three", "two", "one"))
  expect_equal(con$ZREVRANGEBYSCORE(key, "+inf", "-inf"),
               list("three", "two", "one"))

  expect_equal(con$ZREVRANGEBYSCORE(key, 2, 1),
               list("two", "one"))
  expect_equal(con$ZREVRANGEBYSCORE(key, 2, "(1"),
               list("two"))
  expect_equal(con$ZREVRANGEBYSCORE(key, "(2", "(1"),
               list())
})

test_that("ZREVRANK", {
  skip_if_cmd_unsupported("ZREVRANK")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$ZADD(key, 1, "one")
  con$ZADD(key, 2, "two")
  con$ZADD(key, 3, "three")

  expect_equal(con$ZREVRANK(key, "one"), 2)
  expect_null(con$ZREVRANK(key, "four"))
})

test_that("ZSCORE", {
  skip_if_cmd_unsupported("ZSCORE")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$ZADD(key, 1, "one")
  expect_equal(con$ZSCORE(key, "one"), "1")
})

test_that("ZINTERSTORE", {
  skip_if_cmd_unsupported("ZINTERSTORE")
  con <- test_hiredis_connection()
  key1 <- rand_str()
  key2 <- rand_str()
  key3 <- rand_str()
  on.exit(con$DEL(c(key1, key2, key3)))

  con$ZADD(key1, 1, "one")
  con$ZADD(key1, 2, "two")
  con$ZADD(key2, 1, "one")
  con$ZADD(key2, 2, "two")
  con$ZADD(key2, 3, "three")

  expect_equal(con$ZUNIONSTORE(key3, 2, c(key1, key2), c(2, 3)), 3)
  expect_equal(con$ZRANGE(key3, 0, -1, "WITHSCORES"),
               list("one", "5", "three", "9", "two", "10"))
})
