context("commands - set")

test_that("SADD", {
  skip_if_cmd_unsupported("SADD")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  expect_equal(con$SADD(key, "Hello"), 1)
  expect_equal(con$SADD(key, "World"), 1)
  expect_equal(con$SADD(key, "World"), 0)
  expect_equal(sort(unlist(con$SMEMBERS(key))), sort(c("Hello", "World")))
})

test_that("SCARD", {
  skip_if_cmd_unsupported("SCARD")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SADD(key, "Hello")
  con$SADD(key, "World")
  expect_equal(con$SCARD(key), 2)
})

test_that("SDIFF", {
  skip_if_cmd_unsupported("SDIFF")
  con <- test_hiredis_connection()
  key1 <- rand_str()
  key2 <- rand_str()
  on.exit(con$DEL(c(key1, key2)))

  con$SADD(key1, "a")
  con$SADD(key1, "b")
  con$SADD(key1, "c")
  con$SADD(key2, "c")
  con$SADD(key2, "d")
  con$SADD(key2, "e")
  expect_equal(sort(unlist(con$SDIFF(c(key1, key2)))), sort(c("a", "b")))
})

test_that("SDIFFSTORE", {
  skip_if_cmd_unsupported("SDIFFSTORE")
  con <- test_hiredis_connection()
  key1 <- rand_str()
  key2 <- rand_str()
  key3 <- rand_str()
  on.exit(con$DEL(c(key1, key2, key3)))

  con$SADD(key1, "a")
  con$SADD(key1, "b")
  con$SADD(key1, "c")
  con$SADD(key2, "c")
  con$SADD(key2, "d")
  con$SADD(key2, "e")
  expect_equal(con$SDIFFSTORE(key3, c(key1, key2)), 2)
  expect_equal(sort(unlist(con$SMEMBERS(key3))), sort(c("a", "b")))
})

test_that("SINTER", {
  skip_if_cmd_unsupported("SINTER")
  con <- test_hiredis_connection()
  key1 <- rand_str()
  key2 <- rand_str()
  on.exit(con$DEL(c(key1, key2)))

  con$SADD(key1, "a")
  con$SADD(key1, "b")
  con$SADD(key1, "c")
  con$SADD(key2, "c")
  con$SADD(key2, "d")
  con$SADD(key2, "e")
  expect_equal(con$SINTER(c(key1, key2)), list("c"))
})

test_that("SINTERSTORE", {
  skip_if_cmd_unsupported("SINTERSTORE")
  con <- test_hiredis_connection()
  key1 <- rand_str()
  key2 <- rand_str()
  key3 <- rand_str()
  on.exit(con$DEL(c(key1, key2, key3)))

  con$SADD(key1, "a")
  con$SADD(key1, "b")
  con$SADD(key1, "c")
  con$SADD(key2, "c")
  con$SADD(key2, "d")
  con$SADD(key2, "e")
  expect_equal(con$SINTERSTORE(key3, c(key1, key2)), 1)
  expect_equal(con$SMEMBERS(key3), list("c"))
})

test_that("SISMEMBER", {
  skip_if_cmd_unsupported("SISMEMBER")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SADD(key, "one")
  expect_equal(con$SISMEMBER(key, "one"), 1)
  expect_equal(con$SISMEMBER(key, "two"), 0)
})

test_that("SMEMBERS", {
  skip_if_cmd_unsupported("SMEMBERS")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SADD(key, "hello")
  con$SADD(key, "world")
  res <- con$SMEMBERS(key)
  expect_is(res, "list")
  expect_equal(sort(vcapply(res, identity)), sort(c("hello", "world")))
})

test_that("SMOVE", {
  skip_if_cmd_unsupported("SMOVE")
  con <- test_hiredis_connection()
  key1 <- rand_str()
  key2 <- rand_str()
  on.exit(con$DEL(c(key1, key2)))

  con$SADD(key1, "one")
  con$SADD(key1, "two")
  con$SADD(key2, "three")
  expect_equal(con$SMOVE(key1, key2, "two"), 1)
  expect_equal(con$SMEMBERS(key1), list("one"))
  expect_equal(sort(vcapply(con$SMEMBERS(key2), identity)),
               sort(c("two", "three")))
})

test_that("SPOP", {
  skip_if_cmd_unsupported("SPOP")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  all <- c("one", "two", "three", "four", "five")

  con$SADD(key, all[[1]])
  con$SADD(key, all[[2]])
  con$SADD(key, all[[3]])
  v <- con$SPOP(key)
  expect_true(v %in% all[1:3])
  vals <- con$SMEMBERS(key)
  expect_equal(sort(vcapply(vals, identity)), sort(setdiff(all[1:3], v)))
  con$SADD(key, all[[4]])
  con$SADD(key, all[[5]])
  ## TODO: this bit is only OK for the server at version 3.2 or above
  ## v2 <- con$SPOP(key, 3)
})

test_that("SRANDMEMBER", {
  skip_if_cmd_unsupported("SRANDMEMBER")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  vals <- c("one", "two", "three")
  con$SADD(key, vals)
  expect_true(con$SRANDMEMBER(key) %in% vals)

  v <- vcapply(con$SRANDMEMBER(key, 2), identity)
  expect_equal(length(v), 2)
  expect_false(any(duplicated(v)))
  expect_true(all(v %in% vals))

  v <- vcapply(con$SRANDMEMBER(key, -5), identity)
  expect_equal(length(v), 5)
  expect_true(any(duplicated(v)))
  expect_true(all(v %in% vals))
})

test_that("SREM", {
  skip_if_cmd_unsupported("SREM")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  con$SADD(key, "one")
  con$SADD(key, "two")
  con$SADD(key, "three")
  expect_equal(con$SREM(key, "one"), 1)
  con$SADD(key, "four")
  expect_equal(sort(vcapply(con$SMEMBERS(key), identity)),
               sort(c("two", "three", "four")))
})

test_that("SUNION", {
  skip_if_cmd_unsupported("SUNION")
  con <- test_hiredis_connection()
  key1 <- rand_str()
  key2 <- rand_str()
  on.exit(con$DEL(c(key1, key2)))

  con$SADD(key1, "a")
  con$SADD(key1, "b")
  con$SADD(key1, "c")
  con$SADD(key2, "c")
  con$SADD(key2, "d")
  con$SADD(key2, "e")
  expect_equal(sort(vcapply(con$SUNION(c(key1, key2)), identity)),
               letters[1:5])
})

test_that("SUNIONSTORE", {
  skip_if_cmd_unsupported("SUNIONSTORE")
  con <- test_hiredis_connection()
  key1 <- rand_str()
  key2 <- rand_str()
  key3 <- rand_str()
  on.exit(con$DEL(c(key1, key2, key3)))

  con$SADD(key1, "a")
  con$SADD(key1, "b")
  con$SADD(key1, "c")
  con$SADD(key2, "c")
  con$SADD(key2, "d")
  con$SADD(key2, "e")
  expect_equal(con$SUNIONSTORE(key3, c(key1, key2)), 5)
  expect_equal(sort(vcapply(con$SMEMBERS(key3), identity)),
               letters[1:5])
})

## SSCAN in the scan tests
