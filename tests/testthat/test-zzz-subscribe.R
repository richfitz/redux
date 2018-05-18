## NOTE: while tests should not be ordered, I've put these last (ish)
## because they take a bit longer than the others to run because of
## firing off the publisher instance.  So I only want to run these if
## everything else seems OK.

context("subscription")

test_that("low level", {
  ch <- "foo"
  dat <- start_publisher(ch)
  on.exit(file.remove(dat$filename))

  ## This is the sort of headache that the higher level interface is
  ## meant to remove:
  vals <- list()
  callback <- function(x) {
    vals <<- c(vals, list(x))
    if (as.numeric(x[[3]]) > 0.8) {
      TRUE
    } else {
      FALSE
    }
  }

  con <- test_hiredis_connection()
  env <- environment()
  con$.subscribe(ch, FALSE, callback, env)

  expect_gt(length(vals), 0)

  expect_true(all(vcapply(vals, "[[", 1L) == "message"))
  expect_true(all(vcapply(vals, "[[", 2L) == ch))
  ## The payload:
  v <- as.numeric(vcapply(vals, "[[", 3L))
  expect_true(v[[length(v)]] > 0.8)
  expect_true(all(v[-length(v)] < 0.8))

  expect_equal(names(vals[[1]]), c("type", "channel", "value"))
  expect_equal(length(unique(lapply(vals, names))), 1)
})

test_that("higher level", {
  ch <- "foo"
  dat <- start_publisher(ch)
  on.exit(file.remove(dat$filename))

  transform <- function(x) {
    message(sprintf("[%s] %s: %s", Sys.time(), x$channel, x$value))
    x
  }
  terminate <- function(x) {
    x$value > 0.8
  }

  con <- test_hiredis_connection()
  vals <- con$subscribe(ch, transform = transform, terminate = terminate)
  expect_gt(length(vals), 0)

  expect_true(all(vcapply(vals, "[[", 1L) == "message"))
  expect_true(all(vcapply(vals, "[[", 2L) == ch))
  ## The payload:
  v <- as.numeric(vcapply(vals, "[[", 3L))
  expect_true(v[[length(v)]] > 0.8)
  expect_true(all(v[-length(v)] < 0.8))
})

test_that("higher level: collect n", {
  ch <- "foo"
  dat <- start_publisher(ch)
  on.exit(file.remove(dat$filename))

  con <- test_hiredis_connection()
  vals <- con$subscribe(ch, collect = TRUE, n = 5)

  expect_equal(length(vals), 5)

  ## Collect nothing n times:
  val <- con$subscribe(ch, collect = FALSE, n = 5)
  expect_null(val)
})

test_that("pattern", {
  ch <- c("foo1", "foo2")

  dat <- lapply(ch, start_publisher)
  filename <- vcapply(dat, "[[", "filename")
  on.exit(file.remove(filename))

  con <- test_hiredis_connection()
  vals <- con$subscribe("foo*", pattern = TRUE, collect = TRUE, n = 20)

  expect_equal(length(vals), 20)
  expect_equal(length(vals[[1]]), 4)
  expect_equal(names(vals[[1]]),
               c("type", "pattern", "channel", "value"))

  expect_true(all(vcapply(vals, "[[", "type") == "pmessage"))
  expect_true(all(vcapply(vals, "[[", "pattern") == "foo*"))
  chs <- vcapply(vals, "[[", "channel")
  expect_true(all(chs %in% ch))
  expect_true(all(ch %in% chs))
  v <- as.numeric(vcapply(vals, "[[", "value"))
  expect_true(all(v >= 0.0 & v <= 1.0))
})

## Flood and recover.  This is a low-level regression test for a a
## nasty bug I managed to create earlier where we have queued messages
## *before* the UNSUBSCRIBE was sent but after we detatch from the
## SUBSCRIBE call.
##
## This might happen where we're just too slow to handle them
## efficiently) and issuing of an UNSUBSCRIBE command, here being done
## manually.  Normally, this is not able to be done explicitly because
## the UNSUBSCRIBE is handled in an on.exit call, and because that
## leaves the n_discarded attribute non-fetchable.
test_that("flood and recover", {
  terminate <- function(x) {
    if (as.numeric(x$value) > 0.8) {
      Sys.sleep(.5)
      stop("Detected a disturbance in the force")
    }
    FALSE
  }
  display <- function(x) {
    message(sprintf("[%s] %s: %s", Sys.time(), x$channel, x$value))
    x
  }

  ch <- "foo"
  dat <- start_publisher(ch)
  on.exit(file.remove(dat$filename))

  col <- make_collector()
  fn <- make_callback(display, terminate, col$add, Inf)

  con <- redis_connection()
  ptr <- environment(con$command)$ptr

  ## Directly from the lower-level things
  pattern <- FALSE
  res1 <- try(.Call(redux:::Credux_redis_subscribe, ptr, ch, pattern,
                    fn, .GlobalEnv),
              silent = TRUE)
  res2 <- .Call(redux:::Credux_redis_unsubscribe, ptr, ch, pattern)

  expect_is(res1, "try-error")
  expect_equivalent(res2, list("unsubscribe", ch, 0L))
  expect_gt(attr(res2, "n_discarded"), 0)

  ## This one is important:
  expect_equal(con$command("PING"), redis_status("PONG"))

  ## Again with the higher level interface:
  expect_error(res <- con$subscribe(ch, pattern, fn, .GlobalEnv),
               "Detected a disturbance in the force")
  expect_equal(con$command("PING"), redis_status("PONG"))
})

test_that("error cases", {
  ch <- "foo"
  dat <- start_publisher(ch)
  on.exit(file.remove(dat$filename))

  ## This is the sort of headache that the higher level interface is
  ## meant to remove:
  vals <- list()
  callback <- function(x) {
    vals <<- c(vals, list(x))
    if (as.numeric(x[[3]]) > 0.8) {
      TRUE
    } else {
      FALSE
    }
  }

  con <- test_hiredis_connection()
  env <- environment()
  expect_error(con$.subscribe(NULL, FALSE, callback, env),
               "channel must be character")
  expect_error(con$.subscribe(character(), FALSE, callback, env),
               "At least one channel must be given")
  expect_error(con$.subscribe(ch, NULL, callback, env),
               "pattern must be a scalar")
  expect_error(con$.subscribe(ch, FALSE, NULL, env),
               "callback must be a function")
  expect_error(con$.subscribe(ch, FALSE, callback, NULL),
               "envir must be a environment")
})
