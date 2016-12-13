context("scan")

test_that("scan", {
  skip_if_no_redis()
  con <- hiredis()
  prefix <- rand_str(prefix = "scan:")
  keys <- character(0)
  for (i in seq_len(10)) {
    key <- paste0(prefix, ":", rand_str())
    con$SET(key, runif(1))
    keys <- c(keys, key)
  }

  expect_true(all(vapply(keys, con$EXISTS, integer(1)) == 1L))

  pat <- paste0(prefix, "*")
  res <- scan_find(con, pat)
  expect_equal(sort(res), sort(keys))

  n <- scan_del(con, pat)
  expect_equal(n, 10)

  expect_false(any(vapply(keys, con$EXISTS, integer(1)) == 1L))
  res <- scan_find(con, pat)

  expect_equal(res, character(0))
})

test_that("HSCAN", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  a <- c("a1", "a2", "a3", "b1", "b2", "b3")
  x <- runif(length(a))
  con$HMSET(key, a, x)

  res <- scan_find(con, "a*", type = "HSCAN", key = key)
  expect_is(res, "matrix")
  expect_equal(colnames(res), c("field", "value"))

  v <- grep("^a", a, value = TRUE)
  expect_true(all(v %in% res[, "field"]))
  expect_equal(as.numeric(res[match(v, res[, "field"]), "value"]),
               x[match(v, a)])
})

test_that("SSCAN", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  a <- c("a1", "a2", "a3", "b1", "b2", "b3")
  con$SADD(key, a)

  res <- scan_find(con, "a*", type = "SSCAN", key = key)
  expect_equal(sort(res), a[1:3])
})

test_that("ZSCAN", {
  skip_if_no_redis()
  con <- hiredis()
  key <- rand_str()
  on.exit(con$DEL(key))

  a <- c("a1", "a2", "a3", "b1", "b2", "b3")
  s <- sample(length(a))
  con$ZADD(key, s, a)

  res <- scan_find(con, "a*", type = "ZSCAN", key = key)
  expect_equal(sort(res[, 1]), a[1:3])
  i <- match(a[1:3], res[, 1])
  expect_equal(s[1:3], as.integer(res[i, 2]))
})

test_that("error conditions", {
  expect_error(scan_find(NULL, "foo"),
               "con must be a redis_api object")

  skip_if_no_redis()
  con <- hiredis()
  expect_error(scan_find(con, "foo", type = "HSCAN"),
               "key must be given when using HSCAN")
})
