##' Create a heartbeat instance.  This can be used by running
##' `obj$start()` which will reset the TTL (Time To Live) on `key` every
##' `period` seconds (don't set this too high).  If the R process
##' dies, then the key will expire after `3 * period` seconds (or
##' set `expire`) and another application can tell that this R
##' instance has died.
##'
##' The heartbeat object has three methods:
##'
##' * `is_running()` which returns `TRUE` or
##'   `FALSE` if the heartbeat is/is not running.
##'
##' * `start()` which starts a heartbeat
##'
##' * `stop()` which requests a stop for the heartbeat
##'
##' Heavily inspired by the `doRedis` package.
##' @title Create a heartbeat instance
##'
##' @param key Key to use
##'
##' @param period Timeout period (in seconds)
##'
##' @param expire Key expiry time (in seconds)
##'
##' @param value Value to store in the key.  By default it stores the
##'   expiry time, so the time since last heartbeat can be computed.
##'
##' @param config Configuration parameters passed through to
##'   [redux::redis_config].  Provide as either a named list or a
##'   `redis_config` object.  This allows host, port, password,
##'   db, etc all to be set.  Socket connections (i.e., using
##'   `path` to access Redis over a socket) are not currently
##'   supported.
##'
##' @param start Should the heartbeat be started immediately?
##'
##' @param timeout Time, in seconds, to wait for the heartbeat to
##'   appear.  It should generally appear very quickly (within a
##'   second unless your connection is very slow) so this can be
##'   generally left alone.
##' @export
##' @examples
##'
##' if (redux::redis_available()) {
##'   rand_str <- function() {
##'     paste(sample(letters, 20, TRUE), collapse = "")
##'   }
##'   key <- sprintf("heartbeatr:test:%s", rand_str())
##'   h <- redux::heartbeat(key, 1, expire = 2)
##'   con <- redux::hiredis()
##'
##'   # The heartbeat key exists
##'   con$EXISTS(key)
##'
##'   # And has an expiry of less than 2000ms
##'   con$PTTL(key)
##'
##'   # We can manually stop the heartbeat, and 2s later the key will
##'   # stop existing
##'   h$stop()
##'
##'   # Sys.sleep(2)
##'   # con$EXISTS(key) # 0
##' }
heartbeat <- function(key, period, expire = 3 * period, value = expire,
                      config = NULL, start = TRUE, timeout = 10) {
  ret <- heartbeat_$new(config, key, as.character(value), period, expire)
  if (start) {
    ret$start(timeout)
  }
  ret
}


##' Sends a signal to a heartbeat process that is using key `key`
##'
##' @title Send a signal
##'
##' @param key The heartbeat key
##'
##' @param signal A signal to send (e.g. `tools::SIGINT` or
##'   `tools::SIGKILL`)
##'
##' @param con A hiredis object
##'
##' @export
##' @examples
##' if (redux::redis_available()) {
##'   rand_str <- function() {
##'     paste(sample(letters, 20, TRUE), collapse = "")
##'   }
##'   # Suppose we have a process that exposes a heartbeat running on
##'   # this key:
##'   key <- sprintf("redux:heartbeat:test:%s", rand_str())
##'
##'   # We can send it an interrupt over redis using:
##'   con <- redux::hiredis()
##'   redux::heartbeat_send_signal(con, key, tools::SIGINT)
##' }
heartbeat_send_signal <- function(con, key, signal) {
  assert_scalar_character(key)
  con$RPUSH(heartbeat_key_signal(key), signal)
  invisible()
}


##' @importFrom R6 R6Class
heartbeat_ <- R6::R6Class(
  "heartbeat",

  cloneable = FALSE,

  public = list(
    initialize = function(config, key, value, period, expire) {
      assert_scalar_character(key)
      assert_scalar_character(value)
      assert_scalar_positive_integer(expire)
      assert_scalar_positive_integer(period)

      if (expire <= period) {
        stop("expire must be longer than period")
      }

      private$config <- redis_config(config = config)
      if (private$config$scheme != "redis") {
        stop("Only tcp redis connections are supported")
      }

      private$key <- key
      private$key_signal <- heartbeat_key_signal(key)
      private$value <- value

      private$period <- as.integer(period)
      private$expire <- as.integer(expire)
    },

    ## There is an issue here with _exactly_ what happens where we
    ## have a situation where the heartbeat has been scheduled for
    ## closure but it has not closed.  At some point the other thread
    ## will clear out the pointer and we want to check that it has
    ## been set to NULL.  So when doing the check for keep_going we
    ## need to check that able to read safely.  There's a NULL check
    ## there in the code but it seems unsafe at this point.  I don't
    ## think this is super hard to get right and it only impacts the
    ## keep_going bit so we don't have to lock when dealing with the
    ## BLPOP (which could be fairly slow).
    is_running = function() {
      if (is.null(private$ptr)) {
        FALSE
      } else {
        ## I don't know that this is sensible or not; if this returns
        ## FALSE then it does not mean that the heartbeat is
        ## *absolutely* running because it could have died in the
        ## meantime and we don't check here for the key.  So this
        ## probably needs expanding but it requires a better knowledge
        ## of the real-life failure modes.
        .Call(Cheartbeat_running, private$ptr)
      }
    },

    start = function(timeout = 10) {
      if (self$is_running()) {
        stop("Already running on key ", private$key)
      }
      assert_scalar_numeric(timeout)
      private$ptr <- .Call(Cheartbeat_create,
                           private$config$host,
                           as.integer(private$config$port),
                           private$config$password %||% "",
                           as.integer(private$config$db %||% 0L),
                           private$key, private$value, private$key_signal,
                           private$expire, private$period, timeout)
      invisible(self)
    },

    stop = function(wait = TRUE, timeout = 10) {
      assert_scalar_logical(wait)
      assert_scalar_numeric(timeout)
      if (timeout < 0) {
        stop("timeout must be positive")
      }
      ret <- .Call(Cheartbeat_stop, private$ptr, FALSE, wait,
                   as.numeric(timeout))
      private$ptr <- NULL
      ret
    },

    format = function(...) {
      c("<heartbeat>",
        sprintf("  - running: %s", tolower(self$is_running())),
        sprintf("  - key: %s", private$key),
        sprintf("  - period: %d", private$period),
        sprintf("  - expire: %d", private$expire),
        sprintf("  - redis:\n%s",
                paste0("      ", capture.output(print(private$config))[-1],
                       collapse = "\n")))
    }
  ),

  private = list(
    config = NULL,
    ptr = NULL,
    key = NULL,
    key_signal = NULL,
    period = NULL,
    expire = NULL,
    value = NULL
  ))


heartbeat_key_signal <- function(key) {
  paste0(key, ":signal")
}
