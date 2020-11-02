context("commands - server")

## Tested on the server
test_that("CLIENT KILL", {
  expect_equal(redis_cmds$CLIENT_KILL(ID = "12", SKIPME = "yes"),
               list("CLIENT", "KILL", NULL, list("ID", "12"),
                    NULL, NULL, NULL, list("SKIPME", "yes")))
  expect_equal(redis_cmds$CLIENT_KILL(ID = "11", SKIPME = "no"),
               list("CLIENT", "KILL", NULL, list("ID", "11"),
                    NULL, NULL, NULL, list("SKIPME", "no")))
})

test_that("CLIENT LIST", {
  expect_equal(redis_cmds$CLIENT_LIST(), list("CLIENT", "LIST", NULL))
  expect_equal(redis_cmds$CLIENT_LIST("normal"),
               list("CLIENT", "LIST", list("TYPE", "normal")))
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
               "Do not use CLIENT REPLY")
})

test_that("CLIENT SETNAME", {
  name <- rand_str()
  expect_equal(redis_cmds$CLIENT_SETNAME(name),
               list("CLIENT", "SETNAME", name))
})

## New client commands since version 5-6
test_that("CLIENT ID", {
  expect_equal(redis_cmds$CLIENT_ID(), list("CLIENT", "ID"))
})

test_that("CLIENT ID (server)", {
  skip_if_cmd_unsupported("CLIENT_ID")
  con <- test_hiredis_connection()
  res <- con$CLIENT_ID()
  expect_type(res, "integer")
})

test_that("CLIENT CACHING", {
  expect_error(redis_cmds$CLIENT_CACHING("YES"),
               "Do not use CLIENT CACHING; not supported with this client")
})

test_that("CLIENT GETREDIR", {
  expect_error(redis_cmds$CLIENT_GETREDIR(),
               "Do not use CLIENT GETREDIR; not supported with this client")
})

test_that("CLIENT TRACKING", {
  expect_error(redis_cmds$CLIENT_TRACKING("ON"),
               "Do not use CLIENT TRACKING; not supported with this client")
})

test_that("CLIENT UNBLOCK", {
  expect_equal(redis_cmds$CLIENT_UNBLOCK(1L),
               list("CLIENT", "UNBLOCK", 1L, NULL))
  expect_equal(redis_cmds$CLIENT_UNBLOCK(1L, "ERROR"),
               list("CLIENT", "UNBLOCK", 1L, "ERROR"))
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
  expect_equal(redis_cmds$FLUSHALL(), list("FLUSHALL", NULL))
  expect_equal(redis_cmds$FLUSHALL("ASYNC"), list("FLUSHALL", "ASYNC"))
  expect_error(redis_cmds$FLUSHALL("SYNC"),
               "async must be one of")
})

test_that("FLUSHDB", {
  expect_equal(redis_cmds$FLUSHDB(), list("FLUSHDB", NULL))
  expect_equal(redis_cmds$FLUSHDB("ASYNC"), list("FLUSHDB", "ASYNC"))
  expect_error(redis_cmds$FLUSHDB("SYNC"),
               "async must be one of")
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
  expect_equal(redis_cmds$BGSAVE(), list("BGSAVE", NULL))
  expect_equal(redis_cmds$BGSAVE("SCHEDULE"), list("BGSAVE", "SCHEDULE"))
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

test_that("REPLICAOF", {
  expect_equal(redis_cmds$REPLICAOF("NO", "ONE"),
               list("REPLICAOF", "NO", "ONE"))
})

test_that("SYNC", {
  expect_equal(redis_cmds$SYNC(), list("SYNC"))
})

test_that("LOLWUT", {
  expect_equal(redis_cmds$LOLWUT(), list("LOLWUT", NULL))
  expect_equal(redis_cmds$LOLWUT(5), list("LOLWUT", list("VERSION", 5)))
})

test_that("LOLWUT (server)", {
  skip_if_cmd_unsupported("LOLWUT")
  con <- test_hiredis_connection()
  expect_message(con$LOLWUT())
})

test_that("MEMORY DOCTOR", {
  expect_equal(redis_cmds$MEMORY_DOCTOR(), list("MEMORY", "DOCTOR"))
})

test_that("MEMORY HELP", {
  expect_equal(redis_cmds$MEMORY_HELP(), list("MEMORY", "HELP"))
})

test_that("MEMORY MALLOC_STATS", {
  expect_equal(redis_cmds$MEMORY_MALLOC_STATS(),
               list("MEMORY", "MALLOC-STATS"))
})

test_that("MEMORY PURGE", {
  expect_equal(redis_cmds$MEMORY_PURGE(), list("MEMORY", "PURGE"))
})

test_that("MEMORY PURGE", {
  expect_equal(redis_cmds$MEMORY_PURGE(), list("MEMORY", "PURGE"))
})

test_that("MEMORY STATS", {
  expect_equal(redis_cmds$MEMORY_STATS(), list("MEMORY", "STATS"))
})

test_that("MEMORY USAGE", {
  expect_equal(redis_cmds$MEMORY_USAGE(""), list("MEMORY", "USAGE", "", NULL))
  expect_equal(redis_cmds$MEMORY_USAGE("key"),
               list("MEMORY", "USAGE", "key", NULL))
})

test_that("MODULE LIST", {
  expect_equal(redis_cmds$MODULE_LIST(), list("MODULE", "LIST"))
})

test_that("MODULE LOAD", {
  expect_equal(redis_cmds$MODULE_LOAD("path"),
               list("MODULE", "LOAD", "path", NULL))
})

test_that("MODULE UNLOAD", {
  expect_equal(redis_cmds$MODULE_UNLOAD("name"),
               list("MODULE", "UNLOAD", "name"))
})

test_that("SWAP DB", {
  expect_equal(redis_cmds$SWAPDB(0, 1),
               list("SWAPDB", 0, 1))
})

test_that("LATENCY_DOCTOR", {
  expect_equal(redis_cmds$LATENCY_DOCTOR(), list("LATENCY", "DOCTOR"))
})


test_that("LATENCY_GRAPH", {
  expect_equal(redis_cmds$LATENCY_GRAPH("command"),
               list("LATENCY", "GRAPH", "command"))
})

test_that("LATENCY_HISTORY", {
  expect_equal(redis_cmds$LATENCY_HISTORY("command"),
               list("LATENCY", "HISTORY", "command"))
})

test_that("LATENCY_LATEST", {
  expect_equal(redis_cmds$LATENCY_LATEST(), list("LATENCY", "LATEST"))
})

test_that("LATENCY_RESET", {
  expect_equal(redis_cmds$LATENCY_RESET("command"),
               list("LATENCY", "RESET", "command"))
})

test_that("LATENCY_HELP", {
  expect_equal(redis_cmds$LATENCY_HELP(), list("LATENCY", "HELP"))
})

test_that("HELLO", {
  expect_error(redis_cmds$HELLO(),
               "Do not use HELLO; RESP3 not supported with this client")
})

test_that("PSYNC", {
  expect_error(redis_cmds$PSYNC(),
               "Do not use PSYNC; not supported with this client")
})
