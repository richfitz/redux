context("commands (stream)")

test_that("XADD", {
  skip_if_cmd_unsupported("XADD")
  con <- test_hiredis_connection()
  stream <- rand_str()
  id1 <- con$XADD(stream, "*", c("name", "surname"), c("Sara", "OConnor"))
  id2 <- con$XADD(stream, "*", paste0("field", 1:3), paste0("value", 1:3))
  expect_equal(con$XLEN(stream), 2)
  expect_equal(
    con$XRANGE(stream, "-", "+"),
    list(
      list(
        id1,
        list("name", "Sara", "surname", "OConnor")),
      list(
        id2,
        list("field1", "value1", "field2", "value2", "field3", "value3"))))
})


test_that("XDEL", {
  skip_if_cmd_unsupported("XDEL")
  con <- test_hiredis_connection()
  stream <- rand_str()
  id1 <- con$XADD(stream, "*", "a", 1)
  id2 <- con$XADD(stream, "*", "b", 2)
  id3 <- con$XADD(stream, "*", "c", 3)
  con$XDEL(stream, id2)
  expect_equal(
    con$XRANGE(stream, "-", "+"),
    list(list(id1, list("a", "1")),
         list(id3, list("c", "3"))))
})


test_that("XLEN", {
  skip_if_cmd_unsupported("XLEN")
  con <- test_hiredis_connection()
  stream <- rand_str()
  id1 <- con$XADD(stream, "*", "a", 1)
  id2 <- con$XADD(stream, "*", "b", 2)
  id3 <- con$XADD(stream, "*", "c", 3)
  expect_equal(con$XLEN(stream), 3)
})


## Adopted from the docs examples
test_that("XACK", {
  expect_equal(redis_cmds$XACK("mystream", "mygroup", "1526569495631-0"),
               list("XACK", "mystream", "mygroup", "1526569495631-0"))
})

test_that("XCLAIM", {
  expect_equal(
    redis_cmds$XCLAIM("mystream", "mygroup", "Alice", 3600000,
                      "1526569498055-0"),
    list("XCLAIM", "mystream", "mygroup", "Alice", 3600000, "1526569498055-0",
         NULL, NULL, NULL, NULL, NULL))
})

## This lot feels like it might want splitting apart? XGROUP_CREATE etc?
test_that("XGROUP", {
  expect_equal(
    redis_cmds$XGROUP(CREATE = c("mystream", "consumer-group-name", "$")),
    list("XGROUP", list("CREATE", c("mystream", "consumer-group-name", "$")),
         NULL, NULL, NULL, NULL))
  expect_equal(
    redis_cmds$XGROUP(CREATE = c("mystream", "consumer-group-name", 0)),
    list("XGROUP", list("CREATE", c("mystream", "consumer-group-name", 0)),
         NULL, NULL, NULL, NULL))
  ## TODO: MKSTREAM not supported for CREATE

  expect_equal(
    redis_cmds$XGROUP(DESTROY = c("mystream", "consumer-group-name")),
    list("XGROUP", NULL, NULL,
         list("DESTROY", c("mystream", "consumer-group-name")), NULL, NULL))

  expect_equal(
    redis_cmds$XGROUP(CREATECONSUMER = c("mystream", "consumer-group-name",
                                         "myconsumer123")),
    list("XGROUP", NULL, NULL, NULL,
         list("CREATECONSUMER", c("mystream", "consumer-group-name",
                                  "myconsumer123")), NULL))

  expect_equal(
    redis_cmds$XGROUP(DELCONSUMER = c("mystream", "consumer-group-name",
                                      "myconsumer123")),
    list("XGROUP", NULL, NULL, NULL, NULL,
         list("DELCONSUMER", c("mystream",  "consumer-group-name",
                               "myconsumer123"))))

  expect_equal(
    redis_cmds$XGROUP(SETID = c("mystream", "consumer-group-name", 0)),
    list("XGROUP", NULL,
         list("SETID", c("mystream", "consumer-group-name", 0)),
         NULL, NULL, NULL))
})


test_that("XINFO", {
  expect_equal(
    redis_cmds$XINFO(STREAM = "mystream"),
    list("XINFO", NULL, NULL, list("STREAM", "mystream"), NULL))
  expect_equal(
    redis_cmds$XINFO(GROUPS = "mystream"),
    list("XINFO", NULL, list("GROUPS", "mystream"), NULL, NULL))
  expect_equal(
    redis_cmds$XINFO(CONSUMERS = c("mystream", "mygroup")),
    list("XINFO", list("CONSUMERS", c("mystream", "mygroup")),
         NULL, NULL, NULL))
})


test_that("XTRIM", {
  expect_equal(
    unlist(redis_cmds$XTRIM("mystream", "MAXLEN", 1000)),
    c("XTRIM", "mystream", "MAXLEN", 1000))
  expect_equal(
    unlist(redis_cmds$XTRIM("mystream", "MAXLEN", 1000, "~")),
    c("XTRIM", "mystream", "MAXLEN", "~", "1000"))

  ## not yet supported, in 6.2.x only
  ## expect_equal(
  ##   unlist(redis_cmds$XTRIM("mystream", "MINID", 649085820)),
  ##   c("XTRIM", "mystream", "MINID", 649085820))
})


test_that("XREVRANGE", {
  expect_equal(
    unlist(redis_cmds$XREVRANGE("somestream", "+", "-")),
    c("XREVRANGE", "somestream", "+", "-"))
  expect_equal(
    unlist(redis_cmds$XREVRANGE("somestream", "+", "-", COUNT = 1)),
    c("XREVRANGE", "somestream", "+", "-", "COUNT", 1))
})


test_that("XREAD", {
  expect_equal(
    unlist(redis_cmds$XREAD("STREAMS", "mystream", 0, COUNT = 2)),
    c("XREAD", "COUNT", "2", "STREAMS", "mystream", "0"))
  expect_equal(
    unlist(redis_cmds$XREAD("STREAMS", c("mystream", "writers"),
                            c("0-0", "0-0"), COUNT = 2)),
    c("XREAD", "COUNT", "2", "STREAMS", "mystream", "writers", "0-0", "0-0"))
  expect_equal(
    unlist(redis_cmds$XREAD("STREAMS", "mystream", "$", COUNT = 100,
                            BLOCK = 5000)),
    c("XREAD", "COUNT", "100", "BLOCK", "5000", "STREAMS", "mystream", "$"))
})


test_that("XREADGROUP", {
  expect_equal(
    unlist(redis_cmds$XREADGROUP(c("mygroup", "Alice"), "STREAMS", "mystream",
                                 ">", COUNT = 1)),
    c("XREADGROUP", "GROUP", "mygroup", "Alice", "COUNT", "1", "STREAMS",
      "mystream", ">"))
})


test_that("XPENDING", {
  expect_equal(
    unlist(redis_cmds$XPENDING("mystream", "group55")),
    c("XPENDING", "mystream", "group55"))
  expect_equal(
    unlist(redis_cmds$XPENDING("mystream", "group55", "-", "+", 10)),
    c("XPENDING", "mystream", "group55", "-", "+", 10))
  expect_equal(
    unlist(redis_cmds$XPENDING("mystream", "group55", "-", "+", 10,
                               "consumer-123")),
    c("XPENDING", "mystream", "group55", "-", "+", 10, "consumer-123"))
})
