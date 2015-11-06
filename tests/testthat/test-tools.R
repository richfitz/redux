context("tools")

## Pretty simple tests here; just aiming not to fail.
test_that("parse_info", {
  skip_if_no_redis()
  con <- hiredis()
  skip_if_no_info(con)
  info <- RedisAPI::redis_info(con)
  expect_that(info, is_a("list"))
  dat <- con$INFO()
  expect_that(RedisAPI::parse_info(dat), is_a("list"))
  expect_that(RedisAPI::redis_version(con), equals(info$redis_version))
})

## TODO: not totally clear how this should interact with pipeline; I
## think that the pipeline interface is much nicer and naturally deals
## with errors in a better way.  But it's not atomic of course.
test_that("redis_multi", {
  skip_if_no_redis()
  con <- hiredis()
  id <- rand_str()
  on.exit(con$DEL(id))
  con$DEL(id)
  ok <- RedisAPI::redis_multi(con, {
    con$INCR(id)
    con$INCR(id)
  })
  expect_that(ok, equals(list(1, 2)))

  ## If we get an error, things do *not* get evaluated:
  err <- try(RedisAPI::redis_multi(con, {
    con$INCR(id)
    con$INCR(id)
    stop("abort")
  }), silent=TRUE)
  expect_that(con$GET(id), equals("2"))
  expect_that(err, is_a("try-error"))

  expect_that(con$EXEC(), throws_error("ERR EXEC without MULTI"))
})

test_that("from_redis_hash", {
  skip_if_no_redis()
  from_redis_hash <- RedisAPI::from_redis_hash
  con <- hiredis()

  key <- digest::digest(Sys.time())
  fields <- letters[1:5]
  vals <- 1:5
  con$HMSET(key, fields, vals)
  on.exit(con$DEL(key))

  res <- from_redis_hash(con, key)
  cmp <- setNames(as.character(vals), fields)
  expect_that(all(fields %in% names(res)), is_true())
  expect_that(res[fields], equals(cmp))

  expect_that(from_redis_hash(con, key, f=identity)[fields],
              equals(as.list(cmp)))

  expect_that(from_redis_hash(con, key, "a"), equals(cmp["a"]))
  expect_that(from_redis_hash(con, key, "a", f=identity),
              equals(as.list(cmp)["a"]))

  expect_that(from_redis_hash(con, key, c("a", "xxx")),
              equals(c(a="1", xxx=NA_character_)))

  expect_that(from_redis_hash(con, key, character(0)),
              equals(setNames(character(0), character(0))))
})

test_that("redis_time", {
  skip_if_no_redis()
  con <- hiredis()
  skip_if_no_time(con)

  expect_that(RedisAPI::redis_time(con), is_a("character"))
  expect_that(RedisAPI::redis_time_to_r(RedisAPI::redis_time(con)),
              is_a("POSIXt"))
})

## This is just a really simple test that this works at all:
test_that("scripts", {
  r <- hiredis()
  ## A little lua script
  lua <- '
  local keyname = KEYS[1]
  local value = ARGV[1]
  redis.call("SET", keyname, value)
  redis.call("INCR", keyname)
  return redis.call("GET", keyname)'

  obj <- RedisAPI::redis_scripts(r, set_and_incr=lua)
  r$DEL("foo")
  res <- obj("set_and_incr", "foo", "10")
  expect_that(res, equals("11"))
})
