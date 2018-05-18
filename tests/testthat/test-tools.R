context("tools")

## Pretty simple tests here; just aiming not to fail.
test_that("parse_info", {
  con <- test_hiredis_connection()
  skip_if_no_info(con)
  info <- redis_info(con)
  expect_is(info, "list")
  dat <- con$INFO()
  expect_is(parse_info(dat), "list")
  expect_equal(redis_version(con), info$redis_version)
})

## TODO: not totally clear how this should interact with pipeline; I
## think that the pipeline interface is much nicer and naturally deals
## with errors in a better way.  But it's not atomic of course.

## TODO: of the transaction commands, need to make sure we use all of:
##
## * DISCARD
## * EXEC
## * MULTI
## * UNWATCH
## * WATCH
##
## but at this point I don't think all are used.  WATCH in particular
## might not be possible
test_that("redis_multi", {
  con <- test_hiredis_connection()
  id <- rand_str()
  on.exit(con$DEL(id))
  con$DEL(id)
  ok <- redis_multi(con, {
    con$INCR(id)
    con$INCR(id)
  })
  expect_equal(ok, list(1, 2))

  ## If we get an error, things do *not* get evaluated:
  err <- try(redis_multi(con, {
    con$INCR(id)
    con$INCR(id)
    stop("abort")
  }), silent = TRUE)
  expect_equal(con$GET(id), "2")
  expect_is(err, "try-error")

  expect_error(con$EXEC(), "ERR EXEC without MULTI")
})

test_that("from_redis_hash", {
  con <- test_hiredis_connection()

  key <- rand_str()
  fields <- letters[1:5]
  vals <- 1:5
  con$HMSET(key, fields, vals)
  on.exit(con$DEL(key))

  res <- from_redis_hash(con, key)
  cmp <- setNames(as.character(vals), fields)
  expect_true(all(fields %in% names(res)))
  expect_equal(res[fields], cmp)

  expect_equal(from_redis_hash(con, key, f = identity)[fields],
               as.list(cmp))

  expect_equal(from_redis_hash(con, key, "a"), cmp["a"])
  expect_equal(from_redis_hash(con, key, "a", f = identity),
               as.list(cmp)["a"])

  expect_equal(from_redis_hash(con, key, c("a", "xxx")),
               c(a = "1", xxx = NA_character_))

  expect_equal(from_redis_hash(con, key, character(0)),
               setNames(character(0), character(0)))
})

test_that("redis_time", {
  con <- test_hiredis_connection()
  skip_if_no_time(con)

  expect_is(redis_time(con), "character")
  expect_is(redis_time_to_r(redis_time(con)), "POSIXt")
})

## This is just a really simple test that this works at all:
test_that("scripts", {
  r <- test_hiredis_connection()
  ## A little lua script
  lua <- '
  local keyname = KEYS[1]
  local value = ARGV[1]
  redis.call("SET", keyname, value)
  redis.call("INCR", keyname)
  return redis.call("GET", keyname)'

  key <- rand_str()

  obj <- redis_scripts(r, set_and_incr = lua)
  r$DEL(key)
  res <- obj("set_and_incr", key, "10")
  expect_equal(res, "11")
  r$DEL(key)
})

test_that("parse_client_info", {
  str <- 'id=3 addr=127.0.0.1:56110 fd=6 name= age=0 idle=0 flags=N db=0 sub=0 psub=0 multi=-1 qbuf=0 qbuf-free=32768 obl=0 oll=0 omem=0 events=r cmd=client\n'
  dat <- parse_client_info(str)
  expect_is(dat, "list")
  expect_equal(length(dat), 1)
  expect_is(dat[[1]], "character")
  expect_equal(dat[[1]][["id"]], "3")

  expect_equal(parse_client_info(""), list())
})
