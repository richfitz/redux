## NOTE: while tests should not be ordered, I've put these last (ish)
## because they take a bit longer than the others to run because of
## firing off the publisher instance.  So I only want to run these if
## everything else seems OK.

context("subscription")

test_that("low level", {
  ch <- "foo"
  filename <- start_publisher(ch)
  on.exit(file.remove(filename))

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

  con <- hiredis()
  env <- environment()
  con$.subscribe(ch, FALSE, callback, env)

  expect_that(length(vals), is_more_than(0))

  expect_that(all(vcapply(vals, "[[", 1L) == "message"), is_true())
  expect_that(all(vcapply(vals, "[[", 2L) == ch), is_true())
  ## The payload:
  v <- as.numeric(vcapply(vals, "[[", 3L))
  expect_that(v[[length(v)]] > 0.8, is_true())
  expect_that(all(v[-length(v)] < 0.8), is_true())

  expect_that(names(vals[[1]]), equals(c("type", "channel", "value")))
  expect_that(length(unique(lapply(vals, names))), equals(1))
})

test_that("higher level", {
  ch <- "foo"
  filename <- start_publisher(ch)
  on.exit(file.remove(filename))

  transform <- function(x) {
    message(sprintf("[%s] %s: %s", Sys.time(), x$channel, x$value))
    x
  }
  terminate <- function(x) {
    x$value > 0.8
  }

  con <- hiredis()
  options(error=recover)
  vals <- con$subscribe(ch, transform=transform, terminate=terminate)
  expect_that(length(vals), is_more_than(0))

  expect_that(all(vcapply(vals, "[[", 1L) == "message"), is_true())
  expect_that(all(vcapply(vals, "[[", 2L) == ch), is_true())
  ## The payload:
  v <- as.numeric(vcapply(vals, "[[", 3L))
  expect_that(v[[length(v)]] > 0.8, is_true())
  expect_that(all(v[-length(v)] < 0.8), is_true())
})

test_that("higher level: collect n", {
  ch <- "foo"
  filename <- start_publisher(ch)
  on.exit(file.remove(filename))

  con <- hiredis()
  vals <- con$subscribe(ch, collect=TRUE, n=5)

  expect_that(length(vals), equals(5))

  ## Collect nothing n times:
  val <- con$subscribe(ch, collect=FALSE, n=5)
  expect_that(val, is_null())
})

test_that("pattern", {
  ch <- c("foo1", "foo2")
  filename <- vcapply(ch, start_publisher)
  on.exit(file.remove(filename))

  con <- hiredis()
  vals <- con$subscribe("foo*", pattern=TRUE, collect=TRUE, n=20)

  expect_that(length(vals), equals(20))
  expect_that(length(vals[[1]]), equals(4))
  expect_that(names(vals[[1]]),
              equals(c("type", "pattern", "channel", "value")))

  expect_that(all(vcapply(vals, "[[", "type") == "pmessage"), is_true())
  expect_that(all(vcapply(vals, "[[", "pattern") == "foo*"), is_true())
  chs <- vcapply(vals, "[[", "channel")
  expect_that(all(chs %in% ch), is_true())
  expect_that(all(ch %in% chs), is_true())
  v <- as.numeric(vcapply(vals, "[[", "value"))
  expect_that(all(v >= 0.0 & v <= 1.0), is_true())
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
##
## Unfortunately, this also shows the difficulty of the current
## RedisAPI/redux split.
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
  filename <- start_publisher(ch)
  on.exit(file.remove(filename))

  col <- RedisAPI:::make_collector()
  fn <- RedisAPI:::make_callback(display, terminate, col$add, Inf)

  con <- redis_connection()
  ptr <- environment(con$command)$ptr

  ## Directly from the lower-level things
  pattern <- FALSE
  res1 <- try(.Call(redux:::Credux_redis_subscribe, ptr, ch, pattern,
                    fn, .GlobalEnv),
              silent=TRUE)
  res2 <- .Call(redux:::Credux_redis_unsubscribe, ptr, ch, pattern)

  expect_that(res1, is_a("try-error"))
  expect_that(res2, equals(list("unsubscribe", ch, 0L),
                           check.attributes=FALSE))
  expect_that(attr(res2, "n_discarded"), is_more_than(0))

  ## This one is important:
  expect_that(con$command("PING"), equals(redis_status("PONG")))

  ## Again with the higher level interface:
  expect_that(res <- con$subscribe(ch, pattern, fn, .GlobalEnv),
              throws_error("Detected a disturbance in the force"))
  expect_that(con$command("PING"), equals(redis_status("PONG")))
})
