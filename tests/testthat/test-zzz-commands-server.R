context("commands - server")

## Tested on the server
test_that("CLIENT KILL", {
  skip_if_cmd_unsupported("CLIENT_KILL")
  skip_if_not_isolated_redis()

  find_us <- function(con) {
    dat <- parse_client_info(con$CLIENT_LIST())
    is_client <- vcapply(dat, "[[", "cmd") == "client"
    if (sum(is_client) != 1L) {
      skip("Did not find out connection")
    }
    us <- dat[[which(is_client)]]
  }

  ## Kill by id:
  con <- hiredis()
  us <- find_us(con)
  expect_equal(con$CLIENT_KILL(ID = us[["id"]], SKIPME = "yes"), 0)
  expect_equal(con$CLIENT_KILL(ID = us[["id"]], SKIPME = "no"), 1)
  expect_error(con$PING(), "Failure communicating with the Redis server")

  ## Kill by address
  con <- hiredis()
  us <- find_us(con)
  expect_equal(con$CLIENT_KILL(us[["addr"]]), redis_status("OK"))
  expect_error(con$PING(), "Failure communicating with the Redis server")
})

test_that("CLIENT LIST", {
  skip_if_cmd_unsupported("CLIENT_LIST")
  con <- hiredis()
  x <- con$CLIENT_LIST()
  expect_is(x, "character")
  expect_gte(length(x), 1L)
})

test_that("CLIENT GETNAME", {
  skip_if_cmd_unsupported("CLIENT_GETNAME")
  con <- hiredis()
  expect_null(con$CLIENT_GETNAME())
})

test_that("CLIENT PAUSE", {
  skip_if_cmd_unsupported("CLIENT_PAUSE")
  skip_if_not_isolated_redis()
  con <- hiredis()
  expect_equal(con$CLIENT_PAUSE(1000), redis_status("OK"))
  expect_equal(con$PING(), redis_status("PONG"))

  t <- 100

  con$CLIENT_PAUSE(t)
  t0 <- Sys.time()
  con$PING()
  t1 <- Sys.time()
  expect_gt(as.numeric(t1 - t0, "secs"), t / 1000 - 0.02)
})

test_that("CLIENT REPLY", {
  con <- hiredis()
  expect_error(con$CLIENT_REPLY("SKIP"),
               "Do not use CLIENT_REPLY")
})

test_that("CLIENT SETNAME", {
  skip_if_cmd_unsupported("CLIENT_SETNAME")
  con <- hiredis()
  name <- rand_str()
  expect_equal(con$CLIENT_SETNAME(name), redis_status("OK"))
  expect_equal(con$CLIENT_GETNAME(), name)
  dat <- parse_client_info(con$CLIENT_LIST())
  expect_equal(sum(name == vcapply(dat, "[[", "name")), 1)
})

test_that("COMMAND", {
  ## TODO: we could parse this to do better with determining how to
  ## structure nasry commands a bit better, perhaps.
  skip_if_cmd_unsupported("COMMAND")
  con <- hiredis()
  dat <- con$COMMAND()
  expect_is(dat, "list")

  nms <- vcapply(dat, function(x) x[[1]])
  all(toupper(nms) %in% names(redis))
})

test_that("COMMAND COUNT", {
  skip_if_cmd_unsupported("COMMAND_COUNT")
  con <- hiredis()
  expect_equal(con$COMMAND_COUNT(), length(con$COMMAND()))
})

test_that("COMMAND GETKEYS", {
  ## TODO: this is broken; we need a custom function body for this.
  ##
  ## A nice interface might look like:
  ##
  ##   con$COMMAND_GETKEYS(redis_cmds$MSET(letters[1:3], 1:3))
  ##
  ## but need to deal with empty command things:
  ##
  ##   con$COMMAND_GETKEYS(redis_cmds$SET("a", 1))
  ##
  ## this requires filtering out the NULL values from the list, which
  ## requires calling out to the C code that I use, so there's a bit
  ## of faff involved here, really.
})

test_that("COMMAND INFO", {
  skip_if_cmd_unsupported("COMMAND_INFO")
  con <- hiredis()
  d <- con$COMMAND_INFO(c("get", "set", "eval"))
  dat <- con$COMMAND()
  nm <- vcapply(dat, "[[", 1L)
  expect_equal(d, dat[match(c("get", "set", "eval"), nm)])
})

test_that("CONFIG GET", {
  skip_if_cmd_unsupported("CONFIG_GET")
  con <- hiredis()
  d <- con$CONFIG_GET("*max-*-entries*")
  expect_is(d, "list")
})

test_that("DBSIZE", {
  skip_if_cmd_unsupported("DBSIZE")
  con <- hiredis()
  expect_is(con$DBSIZE(), "integer")
})

test_that("FLUSHALL", {
  skip_if_cmd_unsupported("FLUSHALL")
  skip_if_not_isolated_redis()
  con <- hiredis()
  key <- rand_str()
  con$SET(key, 1)
  expect_gt(con$DBSIZE(), 0)
  expect_equal(con$FLUSHALL(), redis_status("OK"))
  expect_equal(con$DBSIZE(), 0)
})

test_that("FLUSHDB", {
  skip_if_cmd_unsupported("FLUSHDB")
  skip_if_not_isolated_redis()
  con <- hiredis()
  key <- rand_str()
  con$SET(key, 1)
  expect_gt(con$DBSIZE(), 0)
  expect_equal(con$FLUSHDB(), redis_status("OK"))
  expect_equal(con$DBSIZE(), 0)
})

test_that("INFO", {
  skip_if_cmd_unsupported("INFO")
  con <- hiredis()
  expect_is(con$INFO(), "character")
})

test_that("LASTSAVE", {
  skip_if_cmd_unsupported("LASTSAVE")
  con <- hiredis()
  ts <- con$LASTSAVE()
  t <- as.numeric(redis_time(con))
  expect_is(ts, "integer")
  expect_lte(ts, t)
})

test_that("ROLE", {
  skip_if_cmd_unsupported("ROLE")
  con <- hiredis()
  r <- con$ROLE()
  expect_is(r, "list")
})

test_that("SLOWLOG", {
  skip_if_cmd_unsupported("SLOWLOG")
  con <- hiredis()
  expect_is(con$SLOWLOG("LEN"), "integer")
  expect_is(con$SLOWLOG("GET", "1"), "list")
})

test_that("TIME", {
  skip_if_cmd_unsupported("TIME")
  con <- hiredis()
  t <- con$TIME()
  expect_is(t, "list")
  expect_equal(length(t), 2)
})

## Untested on the server

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
