context("commands - acl")

test_that("ACL CAT", {
  expect_equal(redis_cmds$ACL_CAT(), list("ACL", "CAT", NULL))
  expect_equal(redis_cmds$ACL_CAT("read"), list("ACL", "CAT", "read"))
})

test_that("ACL CAT (server)", {
  skip_if_cmd_unsupported("ACL_CAT")
  con <- test_hiredis_connection()
  res <- con$ACL_CAT()
  expect_type(res, "list")
  expect_true("dangerous" %in% unlist(res))
  res <- con$ACL_CAT("dangerous")
  expect_type(res, "list")
  expect_true("acl" %in% unlist(res))
})


test_that("ACL DEL", {
  expect_equal(redis_cmds$ACL_DELUSER("x"), list("ACL", "DELUSER", "x"))
  expect_equal(redis_cmds$ACL_DELUSER(c("x", "y")),
               list("ACL", "DELUSER", c("x", "y")))
})


test_that("ACL GENPASS", {
  expect_equal(redis_cmds$ACL_GENPASS(), list("ACL", "GENPASS", NULL))
  expect_equal(redis_cmds$ACL_GENPASS(256), list("ACL", "GENPASS", 256))
})


test_that("ACL GENPASS (server)", {
  skip_if_cmd_unsupported("ACL_GENPASS")
  con <- test_hiredis_connection()
  expect_match(con$ACL_GENPASS(), "^[[:xdigit:]]{64}$")
  expect_match(con$ACL_GENPASS(128), "^[[:xdigit:]]{32}$")
})


test_that("ACL GETUSER", {
  expect_equal(redis_cmds$ACL_GETUSER("default"),
               list("ACL", "GETUSER", "default"))
})


test_that("ACL GETUSER (server)", {
  skip_if_cmd_unsupported("ACL_GETUSER")
  con <- test_hiredis_connection()
  res <- con$ACL_GETUSER("default")
  expect_type(res, "list")
})


test_that("ACL HELP", {
  expect_equal(redis_cmds$ACL_HELP(), list("ACL", "HELP"))
})


## This is dubiously helpful in its current form
test_that("ACL HELP (server)", {
  skip_if_cmd_unsupported("ACL_HELP")
  con <- test_hiredis_connection()
  res <- con$ACL_HELP()
  expect_type(res, "list")
})


test_that("ACL LIST", {
  expect_equal(redis_cmds$ACL_LIST(), list("ACL", "LIST"))
})


test_that("ACL LIST", {
  skip_if_cmd_unsupported("ACL_LIST")
  con <- test_hiredis_connection()
  res <- con$ACL_LIST()
  expect_match(unlist(res), "^user default", all = FALSE)
})


test_that("ACL LOAD", {
  expect_equal(redis_cmds$ACL_LOAD(), list("ACL", "LOAD"))
})


test_that("ACL LOG", {
  expect_equal(redis_cmds$ACL_LOG(), list("ACL", "LOG", NULL))
  expect_equal(redis_cmds$ACL_LOG("RESET"), list("ACL", "LOG", "RESET"))
  expect_equal(redis_cmds$ACL_LOG(1), list("ACL", "LOG", 1))
})


test_that("ACL SAVE", {
  expect_equal(redis_cmds$ACL_SAVE(), list("ACL", "SAVE"))
})


test_that("ACL SETUSER", {
  expect_equal(redis_cmds$ACL_SETUSER("me"), list("ACL", "SETUSER", "me", NULL))
  expect_equal(redis_cmds$ACL_SETUSER("me", c("reset", "rule", "value")),
               list("ACL", "SETUSER", "me", c("reset", "rule", "value")))
})



test_that("ACL USERS", {
  expect_equal(redis_cmds$ACL_USERS(), list("ACL", "USERS"))
})


test_that("ACL USERS (server)", {
  skip_if_cmd_unsupported("ACL_USERS")
  con <- test_hiredis_connection()
  res <- con$ACL_USERS()
  expect_true("default" %in% unlist(res))
})


test_that("ACL WHOAMI", {
  expect_equal(redis_cmds$ACL_WHOAMI(), list("ACL", "WHOAMI"))
})


test_that("ACL WHOAMI (server)", {
  skip_if_cmd_unsupported("ACL_WHOAMI")
  con <- test_hiredis_connection()
  expect_equal(con$ACL_WHOAMI(), "default")
})
