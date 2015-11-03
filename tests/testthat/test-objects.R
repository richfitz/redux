context("objects")

test_that("Round trip (via Redis)", {
  skip_if_no_redis()
  db <- hiredis()

  RedisAPI::redis_object_set("key1", mtcars, db)
  expect_that(RedisAPI::redis_object_get("key1", db), equals(mtcars))
  expect_that(RedisAPI::redis_object_exists("key1", db), is_true())
  expect_that(RedisAPI::redis_object_type("key1", db), equals("data.frame"))

  expect_that(RedisAPI::redis_object_del("key1", db), is_true())
  expect_that(RedisAPI::redis_object_del("key1", db), is_false())
  expect_that(RedisAPI::redis_object_exists("key1", db), is_false())
  expect_that(RedisAPI::redis_object_type("key1", db), is_null())

  x2 <- mixed_fake_data(100)
  RedisAPI::redis_object_set("key2", x2, db)
  expect_that(RedisAPI::redis_object_get("key2", db), equals(x2))

  expect_that(RedisAPI::redis_object_del("key2", db), is_true())
  expect_that(RedisAPI::redis_object_del("key2", db), is_false())
})
