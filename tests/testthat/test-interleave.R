context("cmd_interleave")

test_that("cmd_interleave", {
  ## Basic cases:
  expect_equal(cmd_interleave("a", "b"), c("a", "b"))
  expect_equal(cmd_interleave(c("a", "b"), c("c", "d")),
               c("a", "c", "b", "d"))

  expect_equal(cmd_interleave("a", list("b")), list("a", "b"))
  expect_equal(cmd_interleave(c("a", "b"), list("c", "d")),
               list("a", "c", "b", "d"))
  expect_equal(cmd_interleave(list("a", "b"), list("c", "d")),
               list("a", "c", "b", "d"))

  ## Things with raw vectors:
  obj <- lapply(1:2, object_to_bin)
  expect_equal(cmd_interleave(c("a", "b"), obj),
               list("a", obj[[1]], "b", obj[[2]]))

  expect_equal(cmd_interleave("a", obj[[1]]),
               list("a", obj[[1]]))
  expect_equal(cmd_interleave(obj[[1]], obj[[2]]),
               obj)
  expect_equal(cmd_interleave(obj[[1]], "b"),
               list(obj[[1]], "b"))

  ## Corner cases:
  expect_equal(cmd_interleave(c(), c()), character(0))
  expect_equal(cmd_interleave(list(), list()), list())
  expect_equal(cmd_interleave(NULL, NULL), character(0))

  ## Conversions:
  expect_equal(cmd_interleave("a", 1L), c("a", "1"))
  expect_equal(cmd_interleave("a", 1.0), c("a", "1"))
  expect_equal(cmd_interleave("a", TRUE), c("a", "1"))

  ## Error cases:
  expect_error(cmd_interleave("a", c()), "b must be length 1")
  expect_error(cmd_interleave(c(), "b"), "b must be length 0")
  expect_error(cmd_interleave("a", sin), "cannot coerce type")
  expect_error(cmd_interleave(c("a", "b"), "c"),
               "b must be length 2")

  ## Raw is stored more like character so that length(raw) is more
  ## like nchar(string).
  expect_error(cmd_interleave(runif(length(obj[[1]])), obj[[1]]),
               "b must be length")
  expect_error(cmd_interleave(obj[[1]], runif(length(obj[[1]]))),
               "b must be length")

  ## 3 arg:
  expect_equal(cmd_interleave("a", "b", "c"), c("a", "b", "c"))
  expect_equal(cmd_interleave("a", "b", NULL), c("a", "b"))
  expect_equal(cmd_interleave(NULL, NULL, NULL), character(0))

  expect_equal(cmd_interleave("a", 1, pi), c("a", 1, pi))
  expect_equal(cmd_interleave("a", raw(4), pi),
               list("a", raw(4), as.character(pi)))
})
