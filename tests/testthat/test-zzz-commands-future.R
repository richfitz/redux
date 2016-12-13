context("commands - future")

test_that("UNLINK", { # generic
  key1 <- rand_str()
  key2 <- rand_str()
  key3 <- rand_str()
  expect_equal(redis_cmds$UNLINK(c(key1, key2, key3)),
               list("UNLINK", c(key1, key2, key3)))
})
