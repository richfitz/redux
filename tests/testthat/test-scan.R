context("scan")

test_that("scan", {
  skip_if_no_redis()
  con <- hiredis()
  prefix <- rand_str(prefix="scan:")
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
