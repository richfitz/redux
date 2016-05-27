##' Support for iterating with \code{SCAN}.  Note that this will
##' generalise soon to support collecting output, \code{SSCAN} and
##' other variants, etc.
##'
##' The functions \code{scan_del} and \code{scan_find} are example
##' functions that delete and find all keys corresponding to a given
##' pattern.
##'
##' @title Iterate over keys using SCAN
##' @param con A \code{redis_api} object
##' @param callback Function that takes a character vector of keys and
##'   does something useful to it.  \code{con$DEL} is one option here
##'   to delete keys that match a pattern.  Unlike R's *apply
##'   functions, callback is called for its side effects and its
##'   return values will be ignored.
##' @param pattern Optional pattern to use.
##' @param ... additional arguments passed through to \code{callback}.
##'   Note that if used, \code{pattern} must be provided (at least as
##'   \code{NULL}).
##' @param count Optional step size (default is Redis' default which
##'   is 10)
##' @param type Type of SCAN to run.  Options are \code{"SCAN"} (the
##'   default), \code{"HSCAN"} (scan through keys of a hash),
##'   \code{"SSCAN"} (scan through elements of a set) and
##'   \code{"ZSCAN"} (scan though elements of a sorted set).  If
##'   \code{type} is not \code{"SCAN"}, then \code{key} must be
##'   provided.  HSCAN and ZSCAN currently do not work usefully.
##' @param key Key to use when running a hash, set or sorted set scan.
##' @export
scan_apply <- function(con, callback, pattern=NULL, ...,
                       count=NULL, type="SCAN", key=NULL) {
  ## TODO: need escape hatch here for rlite which does not support
  ## SCAN yet.  According to the issue on rlite, the best thing to do
  ## is KEYS
  ##
  ## NOTE: for HSCAN, pattern acts on the _value_ and the return value
  ## is a (field, value) pair for each item iterated over.  I presume
  ## the same is true for ZSCAN.
  type <- match.arg(type, c("SCAN", "HSCAN", "SSCAN", "ZSCAN"))
  if (type == "SCAN") {
    scan <- con$SCAN
  } else {
    if (is.null(key)) {
      stop("key must be given when using ", type)
    }
    scan <- function(...) con[[type]](key, ...)
  }
  callback <- match.fun(callback)
  cursor <- 0L
  repeat {
    res <- scan(cursor, pattern, count)
    cursor <- res[[1]]
    callback(as.character(res[[2]]), ...)
    if (cursor == "0") {
      break
    }
  }
}

##' @export
##' @rdname scan_apply
scan_del <- function(con, pattern, count=NULL, type="SCAN", key=NULL) {
  n <- 0L
  del <- function(keys) {
    if (length(keys) > 0L) {
      n <<- n + con$DEL(keys)
    }
  }
  scan_apply(con, del, pattern, count=count, type=type, key=key)
  n
}

##' @export
##' @rdname scan_apply
scan_find <- function(con, pattern, count=NULL, type="SCAN", key=NULL) {
  res <- character(0)
  find <- function(keys) {
    if (length(keys) > 0L) {
      res <<- c(res, keys)
    }
  }
  scan_apply(con, find, pattern, count=count, type=type, key=key)
  unique(res)
}
