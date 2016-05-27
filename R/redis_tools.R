##' Parse and return Redis \code{INFO} data.
##' @title Parse Redis INFO
##' @param con A Redis connection
##' @export
redis_info <- function(con) {
  parse_info(con$INFO())
}

##' @param x character string
##' @export
##' @rdname redis_info
parse_info <- function(x) {
  xx <- strsplit(x, "\r\n", fixed=TRUE)[[1]]
  xx <- strsplit(xx, ":")
  xx <- xx[viapply(xx, length) == 2L]
  keys <- setNames(vcapply(xx, "[[", 2),
                   vcapply(xx, "[[", 1))
  keys <- strsplit(keys, ",", fixed=TRUE)
  keys$redis_version <- numeric_version(keys$redis_version)
  keys
}

##' @export
##' @rdname redis_info
redis_version <- function(con) {
  redis_info(con)$redis_version
}

##' Helper to evaluate a Redis \code{MULTI} statement.  If an error
##' occurs then, \code{DISCARD} is called and the transaction is
##' cancelled.  Otherwise \code{EXEC} is called and the transaction is
##' processed.
##' @title Helper for Redis MULTI
##' @param con A Redis connection object
##' @param expr An expression to evaluate
##' @export
redis_multi <- function(con, expr) {
  discard <- function(e) {
    con$DISCARD()
    stop(e)
  }
  tryCatch(error=discard, {
    con$MULTI()
    eval.parent(expr)
    con$EXEC()
  })
}

##' Convert a Redis hash to a character vector or list.
##' @title Convert Redis hash
##' @param con A Redis connection object
##' @param key key of the hash
##' @param fields Optional vector of fields (if absent, all fields are
##'   retrieved via \code{HGETALL}.
##' @param f Function to apply to the \code{list} of values retrieved
##'   as a single set.  To apply element-wise, this will need to be
##'   run via something like \code{Vectorize}.
##' @param missing What to substitute into the returned vector for
##'   missing elements.  By default an NA will be added.  A
##'   \code{stop} expression is OK and will only be evaluated if
##'   values are missing.
##' @export
from_redis_hash <- function(con, key, fields=NULL, f=as.character,
                            missing=NA_character_) {
  if (is.null(fields)) {
    x <- con$HGETALL(key)
    dim(x) <- c(2, length(x) / 2)
    setNames(f(x[2, ]),
             as.character(x[1, ]))
  } else if (length(fields) == 0L) {
    setNames(f(vector("list", 0)), character(0))
  } else {
    x <- con$HMGET(key, fields)
    ## NOTE: This is needed for the case where missing=NULL, otherwise
    ## it will *delete* the elements.  However, if missing is NULL,
    ## then f should really be a list-returning function otherwise
    ## NULL -> "NULL.
    i <- vlapply(x, is.null)
    if (any(i) && !is.null(missing)) {
      x[vlapply(x, is.null)] <- missing
    }
    setNames(f(x), as.character(fields))
  }
}

##' Get time from Redis and format as a string.
##' @title Get time from Redis
##' @param con A Redis connection object
##' @export
redis_time <- function(con) {
  format_redis_time(con$TIME())
}

##' @export
##' @rdname redis_time
##' @param x a list as returned by \code{TIME}
format_redis_time <- function(x) {
  paste(as.character(x), collapse=".")
}

##' @export
##' @rdname redis_time
redis_time_to_r <- function(x) {
  as.POSIXct(as.numeric(x), origin="1970-01-01")
}
