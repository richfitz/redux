context("commands - server")

## TODO: These are not working terribly well on travis at the moment.
## I need to add a few bits to disable a handful of commands and see
## if I can get the tests to pass.  Then replace skipped tests with
## calls to the command generation code to make sure that the
## appropriate text is generated.

## Tested on the server
test_that("CLIENT KILL", {
  expect_equal(redis_cmds$CLIENT_KILL(ID = "12", SKIPME = "yes"),
               list("CLIENT", "KILL", NULL, list("ID", "12"),
                    NULL, NULL, list("SKIPME", "yes")))
  expect_equal(redis_cmds$CLIENT_KILL(ID = "11", SKIPME = "no"),
               list("CLIENT", "KILL", NULL, list("ID", "11"),
                    NULL, NULL, list("SKIPME", "no")))
})

test_that("CLIENT LIST", {
  expect_equal(redis_cmds$CLIENT_LIST(), list("CLIENT", "LIST"))
})

test_that("CLIENT GETNAME", {
  expect_equal(redis_cmds$CLIENT_GETNAME(), list("CLIENT", "GETNAME"))
})

test_that("CLIENT PAUSE", {
  expect_equal(redis_cmds$CLIENT_PAUSE(1000),
               list("CLIENT", "PAUSE", 1000))
})

test_that("CLIENT REPLY", {
  expect_error(redis_cmds$CLIENT_REPLY("SKIP"),
               "Do not use CLIENT_REPLY")
})

test_that("CLIENT SETNAME", {
  name <- rand_str()
  expect_equal(redis_cmds$CLIENT_SETNAME(name),
               list("CLIENT", "SETNAME", name))
})

test_that("COMMAND", {
  expect_equal(redis_cmds$COMMAND(), list("COMMAND"))
})

test_that("COMMAND COUNT", {
  expect_equal(redis_cmds$COMMAND_COUNT(),
               list("COMMAND", "COUNT"))
})

test_that("COMMAND GETKEYS", {
  cmd <- redis_cmds$MSET(letters[1:3], 1:3)
  expect_equal(redis_cmds$COMMAND_GETKEYS(cmd),
               c(list("COMMAND", "GETKEYS"), cmd))
})

test_that("COMMAND INFO", {
  cmds <- c("get", "set", "eval")
  expect_equal(redis_cmds$COMMAND_INFO(cmds),
               list("COMMAND", "INFO", cmds))
})

test_that("CONFIG GET", {
  query <- "*max-*-entries*"
  expect_equal(redis_cmds$CONFIG_GET(query),
               list("CONFIG", "GET", query))
})

test_that("DBSIZE", {
  expect_equal(redis_cmds$DBSIZE(), list("DBSIZE"))
})

test_that("FLUSHALL", {
  expect_equal(redis_cmds$FLUSHALL(), list("FLUSHALL"))
})

test_that("FLUSHDB", {
  expect_equal(redis_cmds$FLUSHDB(), list("FLUSHDB"))
})

test_that("INFO", {
  expect_equal(redis_cmds$INFO(), list("INFO", NULL))
})

test_that("LASTSAVE", {
  expect_equal(redis_cmds$LASTSAVE(), list("LASTSAVE"))
})

test_that("ROLE", {
  expect_equal(redis_cmds$ROLE(), list("ROLE"))
})

test_that("SLOWLOG", {
  expect_equal(redis_cmds$SLOWLOG("LEN"),
               list("SLOWLOG", "LEN", NULL))
  expect_equal(redis_cmds$SLOWLOG("GET", "1"),
               list("SLOWLOG", "GET", "1"))
})

test_that("TIME", {
  expect_equal(redis_cmds$TIME(), list("TIME"))
})

## Untested on any server
test_that("BGREWRITEAOF", {
  expect_equal(redis_cmds$BGREWRITEAOF(), list("BGREWRITEAOF"))
})

test_that("BGSAVE", {
  expect_equal(redis_cmds$BGSAVE(), list("BGSAVE"))
})

test_that("CONFIG REWRITE", {
  expect_equal(redis_cmds$CONFIG_REWRITE(), list("CONFIG", "REWRITE"))
})

test_that("CONFIG SET", {
  expect_equal(redis_cmds$CONFIG_SET("SAVE", "900 1 300 10"),
               list("CONFIG", "SET", "SAVE", "900 1 300 10"))
})

test_that("CONFIG RESETSTAT", {
  expect_equal(redis_cmds$CONFIG_RESETSTAT(),
               list("CONFIG", "RESETSTAT"))
})

test_that("DEBUG OBJECT", {
  ## TODO: possibly worth excluding this entirely?
  expect_equal(redis_cmds$DEBUG_OBJECT("key"),
               list("DEBUG", "OBJECT", "key"))
})

test_that("DEBUG SEGFAULT", {
  ## TODO: possibly worth excluding this entirely?
  expect_equal(redis_cmds$DEBUG_SEGFAULT(),
               list("DEBUG", "SEGFAULT"))
})

test_that("MONITOR", {
  ## TODO: possibly worth excluding this entirely?
  expect_equal(redis_cmds$MONITOR(),
               list("MONITOR"))
})

test_that("SAVE", {
  expect_equal(redis_cmds$SAVE(), list("SAVE"))
})

test_that("SHUTDOWN", {
  expect_equal(redis_cmds$SHUTDOWN("SAVE"), list("SHUTDOWN", "SAVE"))
  expect_equal(redis_cmds$SHUTDOWN("NOSAVE"), list("SHUTDOWN", "NOSAVE"))
})

test_that("SLAVEOF", {
  expect_equal(redis_cmds$SLAVEOF("NO", "ONE"), list("SLAVEOF", "NO", "ONE"))
})

test_that("SYNC", {
  expect_equal(redis_cmds$SYNC(), list("SYNC"))
})
