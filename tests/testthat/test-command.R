context("cmd_command")

test_that("cmd_command", {
  expect_null(cmd_command("foo", NULL, FALSE))
  expect_equal(cmd_command("foo", 1, FALSE), list("foo", 1))
  expect_equal(cmd_command("foo", 1:2, FALSE), c("foo", 1, "foo", 2))
  ## Type conversions:
  expect_equal(cmd_command("foo", c(TRUE, FALSE), FALSE),
              c("foo", 1, "foo", 0))

  expect_null(cmd_command("foo", NULL, TRUE))
  expect_equal(cmd_command("foo", 1, TRUE), list("foo", 1))
  expect_equal(cmd_command("foo", 1:2, TRUE), list("foo", 1:2))
})
