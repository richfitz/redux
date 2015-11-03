context("scan")

test_that("scan", {
  con <- hiredis()
  prefix <- rand_str(prefix="scan:")
  keys <- character(0)
  for (i in seq_len(10)) {
    key <- paste0(prefix, ":", rand_str())
    con$SET(key, runif(1))
    keys <- c(keys, key)
  }

  expect_that(all(vapply(keys, con$EXISTS, integer(1)) == 1L), is_true())

  pat <- paste0(prefix, "*")
  res <- RedisAPI::scan_find(con, pat)
  expect_that(sort(res), equals(sort(keys)))

  n <- RedisAPI::scan_del(con, pat)
  expect_that(n, equals(10))

  expect_that(any(vapply(keys, con$EXISTS, integer(1)) == 1L), is_false())
  res <- RedisAPI::scan_find(con, pat)

  expect_that(res, equals(character(0)))
})
