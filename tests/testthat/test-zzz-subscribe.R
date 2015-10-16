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

  ptr <- redis_connect_tcp("127.0.0.1", 6379L)
  env <- environment()
  redis_subscribe(ptr, ch, callback, env)

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
  ptr <- redis_connect_tcp("127.0.0.1", 6379L)

  vals <- subscribe2(ptr, ch, transform, terminate, environment(),
                     collect=TRUE)

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

  ptr <- redis_connect_tcp("127.0.0.1", 6379L)
  vals <- subscribe2(ptr, ch, NULL, NULL,
                     envir=environment(), collect=TRUE, n=5)

  expect_that(length(vals), equals(5))

  ## Collect nothing n times:
  val <- subscribe2(ptr, ch, NULL, NULL,
                    envir=environment(), collect=FALSE, n=5)
  expect_that(val, is_null())
})

## Flood and recover.  Try to trigger the issue from earlier where we
## have queued messages *before* the UNSUBSCRIBE was sent but after we
## detatch from the SUBSCRIBE call.
test_that("flood and recover", {
  ## This simulates a problem where there is a gap between handing
  ## messages (or where we're just too slow to handle them
  ## efficiently) and issuing of an UNSUBSCRIBE command, here being
  ## done manually.  Normally, this is not able to be done explicitly
  ## because the UNSUBSCRIBE is handled in an on.exit call.
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

  col <- make_collector()
  fn <- make_callback(display, terminate, col$add, Inf)

  ptr <- redis_connect_tcp("127.0.0.1", 6379L)

  ## Directly from the lower-level things
  res1 <- try(.Call(Credux_redis_subscribe, ptr, ch, fn, .GlobalEnv),
              silent=TRUE)
  res2 <- .Call(Credux_redis_unsubscribe, ptr, ch)

  expect_that(res1, is_a("try-error"))
  expect_that(res2, equals(list("unsubscribe", ch, 0L),
                           check.attributes=FALSE))
  expect_that(attr(res2, "n_discarded"), is_more_than(0))

  ## This one is important:
  expect_that(redis_command(ptr, "PING"), equals(redis_status("PONG")))

  ## Again with the higher level interface:

  expect_that(res <- redis_subscribe(ptr, ch, fn, .GlobalEnv),
              throws_error("Detected a disturbance in the force"))
  expect_that(redis_command(ptr, "PING"), equals(redis_status("PONG")))
})
