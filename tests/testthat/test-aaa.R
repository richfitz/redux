context("redux (basic test)")

test_that("use", {
  skip_if_no_redis()
  r <- hiredis()
  expect_that(r$PING(), equals(redis_status("PONG")))
  key <- "redisapi-test:foo"
  expect_that(r$SET(key, "bar"), equals(redis_status("OK")))
  expect_that(r$GET(key), equals("bar"))
  r$DEL(key)
})

test_that("rdb", {
  r <- RedisAPI::rdb(hiredis)
  x <- mtcars
  expect_that(r$set("foo", x), is_null())
  expect_that(r$get("foo"), equals(x))
  expect_that("foo" %in% r$keys(), is_true())
  expect_that(r$exists("foo"), is_true())
  r$del("foo")
  expect_that("foo" %in% r$keys(), is_false())
  expect_that(r$exists("foo"), is_false())
})
