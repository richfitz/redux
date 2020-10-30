context("config")

## Url splitting (why isn't this in base R? It doesn't seem worth
## adding a whole dependency for)
test_that("url parse", {
  f <- function(host, port = NULL, password = NULL, db = NULL, scheme = NULL) {
    list(scheme = scheme, password = password, host = host, port = port,
         db = db)
  }
  expect_equal(parse_redis_url("localhost"),
               f("localhost"))
  expect_equal(parse_redis_url("redis://localhost"),
               f("localhost", scheme = "redis"))
  expect_equal(parse_redis_url("redis://localhost:999"),
               f("localhost", scheme = "redis", port = 999L))
  expect_equal(parse_redis_url("redis://:foo@localhost:999"),
               f("localhost", scheme = "redis", port = 999L,
                 password = "foo"))
  expect_equal(parse_redis_url("redis://:foo@localhost:999/2"),
               f("localhost", scheme = "redis", port = 999L,
                 password = "foo", db = 2L))

  expect_equal(parse_redis_url("redis://127.0.0.1:999"),
               f("127.0.0.1", scheme = "redis", port = 999L))

  ## Allow underscores, even though they're not valid, because they
  ## are useful in docker
  expect_equal(parse_redis_url("redis://local_host"),
               f("local_host", scheme = "redis"))

  ## Failures (not enough tests)
  expect_error(parse_redis_url(""), "Failed to parse URL")
})

test_that("defaults", {
  ## Defaults, same as redis-rb, seem pretty reasonable to me:
  obj <- redis_config(url = "redis://127.0.0.1:6379")
  expect_equal(obj$host, "127.0.0.1")
  expect_equal(obj$port, 6379L)
  expect_null(obj$db)
  expect_null(obj$password)
  expect_null(obj$path)
  expect_equal(obj$scheme, "redis")
  expect_equal(obj$url, "redis://127.0.0.1:6379")
})

test_that("NULL config OK", {
  expect_identical(redis_config(), redis_config(config = NULL))
  expect_identical(redis_config(), redis_config(config = list()))
})

test_that("url", {
  obj <- redis_config(url = "redis://:secr3t@foo.com:999/2")
  expect_equal(obj$host, "foo.com")
  expect_equal(obj$port, 999L)
  expect_equal(obj$db, 2L)
  expect_equal(obj$password, "secr3t")
  expect_equal(obj$url, "redis://:secr3t@foo.com:999/2")
})

test_that("unescape password", {
  obj <- redis_config(url = "redis://:secr3t%3A@foo.com:999/2")
  expect_equal(obj$password, "secr3t:")
})

test_that("don't unescape password when explicitly passed", {
  obj <- redis_config(url = "redis://:secr3t%3A@foo.com:999/2",
                      password = "secr3t%3A")
  expect_equal(obj$password, "secr3t%3A")
})

test_that("path overrides URL", {
  obj <- redis_config(url = "redis://:secr3t@foo.com:999/2",
                      path = "/tmp/redis.sock")
  expect_equal(obj$path, "/tmp/redis.sock")
  expect_null(obj$host)
  expect_null(obj$port)
  ## These still get picked up though.
  expect_equal(obj$password, "secr3t")
  expect_equal(obj$db,   2L)
})

test_that("NULL options do not override", {
  obj <- redis_config(url = "redis://:secr3t@foo.com:999/2",
                      port = NULL)
  expect_equal(obj$port, 999L)
})

test_that("url environment variable", {
  oo <- sys_setenv(REDIS_URL = "redis://:secr3t@foo.com:999/2")
  on.exit(sys_resetenv(oo))
  obj <- redis_config()
  expect_equal(obj$host,     "foo.com")
  expect_equal(obj$port,     999L)
  expect_equal(obj$db,       2L)
  expect_equal(obj$password, "secr3t")
})

test_that("host environment variable", {
  oo <- sys_setenv(REDIS_HOST = "myhost")
  on.exit(sys_resetenv(oo))
  obj <- redis_config()
  expect_equal(obj$host, "myhost")
  expect_is(obj$port, "integer")

  obj <- redis_config(host = "other")
  expect_equal(obj$host, "other")

  ## How does this interact with URL?  Looks like URL currently replaces host.
  oo2 <- sys_setenv(REDIS_URL = "redis://:secr3t@foo.com:999/2")
  on.exit(sys_resetenv(oo2), add = TRUE)
  obj <- redis_config()
  expect_equal(obj$host, "foo.com")
})

test_that("port environment variable", {
  oo <- sys_setenv(REDIS_PORT = "9999")
  on.exit(sys_resetenv(oo))
  obj <- redis_config()
  expect_equal(obj$host, "127.0.0.1")
  expect_equal(obj$port, 9999L)

  ## How does this interact with URL?  Looks like URL currently replaces port.
  oo2 <- sys_setenv(REDIS_URL = "redis://:secr3t@foo.com:999/2")
  on.exit(sys_resetenv(oo2), add = TRUE)
  obj <- redis_config()
  expect_equal(obj$host, "foo.com")
  expect_equal(obj$port, 999L)
})

test_that("redis_config", {
  cfg <- redis_config()
  expect_is(cfg, "redis_config")
  expect_equal(redis_config(cfg), cfg)
  expect_equal(redis_config(config = cfg), cfg)
  expect_warning(cfg2 <- redis_config(host = "foo", config = cfg),
                 "Ignoring dots in favour of config")
  expect_equal(cfg2, cfg)
})

test_that("list argument", {
  cfg <- list(host = "foo", port = 8888)
  config <- redis_config(cfg)
  expect_equal(config$host, "foo")
  expect_equal(config$port, 8888)

  expect_error(redis_config(cfg, db = 1), "Invalid configuration")
  expect_error(redis_config(db = 1, cfg), "must be named")
  expect_error(redis_config(db = 1, other = cfg), "must be scalar")

  expect_warning(cfg2 <- redis_config(db = 1, config = cfg), "Ignoring dots")
  expect_null(cfg2$db)
})

test_that("unknowns", {
  expect_warning(cfg <- redis_config(foo = 1), "Unknown fields in defaults")
  expect_null(cfg$foo)
})

test_that("non-named args", {
  expect_error(redis_config("foo"), "must be named")
})

test_that("print", {
  expect_output(print(redis_config(), "Redis config"))
})
