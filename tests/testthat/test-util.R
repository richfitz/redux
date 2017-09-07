context("util")

test_that("assertions work", {
  expect_error(assert_scalar(NULL), "must be a scalar")
  expect_error(assert_scalar(numeric(0)), "must be a scalar")
  expect_error(assert_scalar(1:2), "must be a scalar")

  expect_error(assert_scalar_logical(1), "must be logical")
  expect_error(assert_scalar_logical(NA), "must not be NA")
  expect_error(assert_scalar_logical(c(TRUE, TRUE)), "must be a scalar")

  expect_error(assert_scalar_character(character(0)), "must be a scalar")
  expect_error(assert_scalar_character(c("a", "b")), "must be a scalar")
  expect_error(assert_scalar_character(1), "must be character")
  expect_error(assert_scalar_character(NA_character_), "must not be NA")

  expect_error(assert_match_value("a", c("b", "c")),
               "must be one of", fixed = TRUE)

  expect_error(assert_length(NULL, 2), "must be length 2")
  expect_error(assert_length("a", 2), "must be length 2")
  expect_error(assert_length(1:3, 2), "must be length 2")

  expect_silent(assert_scalar_or_raw("a"))
  expect_silent(assert_scalar_or_raw(as.raw(0:20)))
  expect_error(assert_scalar_or_raw(1:2),
               "must be a scalar")

  expect_error(assert_raw(1), "must be raw")

  expect_silent(assert_scalar_or_null(NULL))
  expect_silent(assert_scalar_or_null(1))
  expect_error(assert_scalar_or_null(character(0)),
               "must be a scalar")

  expect_error(assert_scalar2(1:2),
               "must be a scalar")

  expect_silent(assert_length_or_null2(NULL))
  expect_silent(assert_length_or_null2(as.raw(0:20), 1))

  expect_error(assert_named(1:4), "must be named")
  expect_error(assert_named(setNames(1:3, c("a", "b", ""))),
               "must be named")
  expect_silent(assert_named(character(0)))
  expect_error(assert_named(character(0), FALSE),
               "must be named")
  expect_error(assert_named(setNames(1:2, c("a", "a"))),
               "must have unique names")

  expect_error(assert_is(NULL, "function"),
               "must be a function")
})

test_that("hiredis_function", {
  expect_error(hiredis_function("foo", list(a = identity), required = TRUE),
               "Interface function foo required")
  f <- hiredis_function("foo", structure(list(), type = "bar"), FALSE)
  expect_is(f, "function")
  expect_error(f(), "foo is not supported with the bar interface")
})

test_that("str_drop_start", {
  expect_equal(str_drop_start("foo:bar", "xxx:"), "bar")
})
