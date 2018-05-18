context("commands - hyperloglog")

test_that("PFADD", {
  skip_if_cmd_unsupported("PFADD")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  expect_equal(con$PFADD(key, letters[1:7]), 1L)
  expect_equal(con$PFCOUNT(key), 7L)
})

test_that("PFCOUNT", {
  skip_if_cmd_unsupported("PFCOUNT")
  con <- test_hiredis_connection()
  key <- rand_str()
  on.exit(con$DEL(key))

  expect_equal(con$PFADD(key, c("foo", "bar", "zap")), 1)
  expect_equal(con$PFADD(key, c("foo", "bar", "zap")), 0)
  expect_equal(con$PFADD(key, c("foo", "bar")), 0)
  expect_equal(con$PFCOUNT(key), 3)
})

test_that("PFMERGE", {
  skip_if_cmd_unsupported("PFMERGE")
  con <- test_hiredis_connection()
  key1 <- rand_str()
  key2 <- rand_str()
  key3 <- rand_str()
  on.exit(con$DEL(c(key1, key2, key3)))

  expect_equal(con$PFADD(key1, c("foo", "bar", "zap", "a")), 1)
  expect_equal(con$PFADD(key2, c("a", "b", "c", "foo")), 1)
  con$PFMERGE(key3, c(key1, key2))
  expect_equal(con$PFCOUNT(key3), 6)
})
