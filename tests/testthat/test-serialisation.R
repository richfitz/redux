test_that("string serialisation is transitive", {
  f <- function(x, identical = TRUE) {
    y <- string_to_object(object_to_string(x))
    is_equivalent_to <- if (identical) is_identical_to else equals
    expect_equal(x, y, ignore_attr = TRUE)
  }
  f(NULL)
  f(1)
  f(pi)
  f(1:10)

  set.seed(1)
  x <- runif(100)
  expect_identical(string_to_object(object_to_string(x)), x)
  f(x, FALSE)
})

test_that("binary serialisation is transitive", {
  f <- function(x, identical = TRUE) {
    y <- bin_to_object(object_to_bin(x))
    is_equivalent_to <- if (identical) is_identical_to else equals
    expect_equal(x, y, ignore_attr = TRUE)
  }
  f(NULL)
  f(1)
  f(1:10)

  ## In contrast with string serialization above, binary serialization
  ## is exact (as well as being about 10x faster which is nice).
  set.seed(1)
  x <- runif(100)
  f(x)
})
