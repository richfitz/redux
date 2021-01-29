context("heartbeat")

test_that("basic", {
  skip_if_no_redis()
  config <- redis_config()
  key <- "heartbeat_key:basic"
  period <- 1
  expire <- 2
  obj <- heartbeat(key, period, expire = expire, start = FALSE)
  expect_is(obj, "heartbeat")
  expect_is(obj, "R6")

  con <- hiredis()
  expect_equal(con$EXISTS(key), 0)
  on.exit(con$DEL(key))
  expect_false(obj$is_running())

  obj$start()
  expect_equal(con$EXISTS(key), 1)
  expect_equal(con$GET(key), as.character(expire))
  ttl <- con$TTL(key)

  expect_gt(ttl, period - expire)
  expect_lte(ttl, expire)
  expect_true(obj$is_running())

  expect_error(obj$start(), "Already running on key")
  expect_true(obj$is_running())

  expect_true(obj$stop())
  expect_false(obj$is_running())
  expect_equal(con$EXISTS(key), 0)
})


test_that("Garbage collection", {
  skip_if_no_redis()
  key <- "heartbeat_key:gc"
  period <- 1
  expire <- 2
  con <- redux::hiredis()

  obj <- heartbeat(key, period, expire = expire)
  expect_equal(con$EXISTS(key), 1)
  expect_true(obj$is_running())

  rm(obj)
  gc()
  Sys.sleep(0.5)
  expect_equal(con$EXISTS(key), 0)
})


test_that("Send signals", {
  skip_if_no_redis()
  skip_on_os("windows")
  key <- "heartbeat_key:signals"
  period <- 10
  expire <- 20
  con <- redux::hiredis()
  on.exit(con$DEL(key))

  obj <- heartbeat(key, period, expire = expire, start = TRUE)
  expect_equal(con$EXISTS(key), 1)
  expect_true(obj$is_running())

  idx <- 0
  dt <- 0.1
  f <- function() {
    for (i in 1:(expire * dt)) {
      idx <<- i
      if (i > 1) {
        heartbeat_send_signal(con, key, tools::SIGINT)
      }
      Sys.sleep(dt)
    }
    i
  }

  ans <- tryCatch(f(), interrupt = function(e) TRUE)
  expect_true(ans)
  expect_gte(idx, 1)
  expect_lt(idx, 10)
  expect_true(obj$is_running())
  obj$stop()
})


test_that("auth", {
  skip_if_not_isolated_redis()
  con <- redux::hiredis()

  key <- "heartbeat_key:auth"
  password <- "password"

  con$CONFIG_SET("requirepass", password)
  con$AUTH(password)
  on.exit(con$CONFIG_SET("requirepass", ""))

  expect_error(redux::hiredis()$PING(), "NOAUTH")

  period <- 1
  expire <- 2
  obj <- heartbeat(key, period, expire = expire,
                   config = list(password = password))
  expect_is(obj, "heartbeat")
  expect_is(obj, "R6")
  expect_true(obj$is_running())
  expect_equal(con$EXISTS(key), 1)
  expect_true(obj$stop())
  expect_false(obj$is_running())
  expect_equal(con$EXISTS(key), 0)
})


test_that("db", {
  skip_if_no_redis()
  con <- redux::hiredis()

  key <- "heartbeat_key:db"
  db <- 3L

  con$SELECT(db)

  period <- 1
  expire <- 2
  obj <- heartbeat(key, period, expire = expire, config = list(db = db))

  expect_is(obj, "heartbeat")
  expect_is(obj, "R6")
  expect_true(obj$is_running())
  expect_equal(con$EXISTS(key), 1)
  expect_true(obj$stop())
  expect_false(obj$is_running())
  expect_equal(con$EXISTS(key), 0)
})


test_that("dying process", {
  skip_if_no_redis()
  skip_if_not_installed("sys")
  Sys.setenv(R_TESTS = "")

  con <- redux::hiredis()
  expire <- 2
  host <- con$config()$host
  port <- con$config()$port

  key <- "heartbeat_key:die"
  rscript <- file.path(R.home("bin"), "Rscript")
  args <- c("run-heartbeat.R", host, port, key, 1, expire, 600)

  px <- sys::exec_background(rscript, args, std_out = FALSE, std_err = FALSE)
  is_alive <- function(px) {
    is.na(sys::exec_status(px, FALSE))
  }

  timeout <- 2
  dt <- 0.01
  for (i in seq_len(timeout / dt)) {
    if (con$EXISTS(key) == 1) {
      break
    }
    if (!is_alive(px)) {
      break
    }
    Sys.sleep(dt)
  }

  expect_equal(con$EXISTS(key), 1)
  tools::pskill(px)
  Sys.sleep(0.5)
  expect_equal(con$EXISTS(key), 1)
  expect_false(is_alive(px))
  Sys.sleep(expire)
  expect_equal(con$EXISTS(key), 0)
})


test_that("pointer handling", {
  skip_if_no_redis()
  key <- "heartbeat_key:basic"
  period <- 1
  expire <- 2
  obj <- heartbeat(key, period, expire = expire, start = TRUE)

  private <- environment(obj$initialize)$private
  ptr <- private$ptr
  null_ptr <- unserialize(serialize(ptr, NULL))

  obj$stop()

  expect_error(.Call(Cheartbeat_stop, NULL, TRUE, FALSE, 1),
               "Expected an external pointer")
  expect_error(.Call(Cheartbeat_stop, null_ptr, TRUE, FALSE, 1),
               "already freed")
})


test_that("connnection failure", {
  skip_if_no_redis()
  key <- "heartbeat_key:confail"
  period <- 1
  expire <- 2

  con <- redux::hiredis()

  expect_error(
    heartbeat(key, period, expire = expire,
              config = list(port = 9999), start = TRUE),
    "Failed to create heartbeat: redis connection failed")
  expect_equal(con$EXISTS(key), 0)

  expect_error(
    heartbeat(key, period, expire = expire,
              config = list(password = "yo"), start = TRUE),
    "Failed to create heatbeat: authentication refused")
  expect_equal(con$EXISTS(key), 0)

  expect_error(
    heartbeat(key, period, expire = expire,
              config = list(db = 99), start = TRUE),
    "Failed to create heatbeat: could not SELECT db")
  expect_equal(con$EXISTS(key), 0)

  expect_error(
    heartbeat(key, period, timeout = 0),
    "Failed to create heartbeat: did not come up in time")
  Sys.sleep(0.25)
  expect_equal(con$EXISTS(key), 0)

  skip_if_not_isolated_redis()
  password <- "yolo"
  con$CONFIG_SET("requirepass", password)
  con$AUTH(password)
  on.exit(con$CONFIG_SET("requirepass", ""))
  expect_error(
    heartbeat(key, period, expire = expire, start = TRUE),
    "Failed to create heatbeat: could not SET (password required?)",
    fixed = TRUE)
  expect_equal(con$EXISTS(key), 0)
})


test_that("connnection failure", {
  skip_if_no_redis()
  key <- "heartbeat_key:confail"
  period <- 1
  expire <- 2

  con <- redux::hiredis()

  expect_error(
    heartbeat(key, period, expire = expire,
              config = list(port = 9999), start = TRUE),
    "Failed to create heartbeat: redis connection failed")
  expect_equal(con$EXISTS(key), 0)

  expect_error(
    heartbeat(key, period, expire = expire,
              config = list(password = "yo"), start = TRUE),
    "Failed to create heatbeat: authentication refused")
  expect_equal(con$EXISTS(key), 0)

  expect_error(
    heartbeat(key, period, expire = expire,
              config = list(db = 99), start = TRUE),
    "Failed to create heatbeat: could not SELECT db")
  expect_equal(con$EXISTS(key), 0)

  expect_error(
    heartbeat(key, period, timeout = 0),
    "Failed to create heartbeat: did not come up in time")
  Sys.sleep(0.25)
  expect_equal(con$EXISTS(key), 0)

  skip_if_not_isolated_redis()
  password <- "yolo"
  con$CONFIG_SET("requirepass", password)
  con$AUTH(password)
  on.exit(con$CONFIG_SET("requirepass", ""))
  expect_error(
    heartbeat(key, period, expire = expire, start = TRUE),
    "Failed to create heatbeat: could not SET (password required?)",
    fixed = TRUE)
  expect_equal(con$EXISTS(key), 0)
})


test_that("invalid times", {
  key <- "heartbeat_key:confail"
  period <- 10
  expect_error(heartbeat(key, period, expire = period),
               "expire must be longer than period")
  expect_error(heartbeat(key, period, expire = period - 1),
               "expire must be longer than period")
})


test_that("positive timeout", {
  skip_if_no_redis()
  key <- "heartbeat_key:basic"
  period <- 1
  obj <- heartbeat(key, period, start = FALSE)
  expect_error(obj$stop(wait = TRUE, timeout = -1), "timeout must be positive")
})


test_that("print", {
  skip_if_no_redis()
  key <- "heartbeat_key:print"
  period <- 1
  obj <- heartbeat(key, period, start = FALSE)
  str <- capture.output(tmp <- print(obj))
  expect_identical(tmp, obj)
  expect_match(str, "<heartbeat>", fixed = TRUE, all = FALSE)
  expect_match(str, "running: false", fixed = TRUE, all = FALSE)
})


test_that("disallow socket connection", {
  key <- "heartbeat_key:socket"
  period <- 1
  expect_error(heartbeat(key, period,
                         config = list(path = tempdir()),
                         start = FALSE),
               "Only tcp redis connections are supported")
})
