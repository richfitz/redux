##' Parse and return Redis \code{INFO} data.
##' @title Parse Redis INFO
##' @param con A Redis connection
##' @export
##' @examples
##' if (redux::redis_available()) {
##'   r <- redux::hiredis()
##'
##'   # Redis server version:
##'   redux::redis_version(r)
##'   # This is a 'numeric_version' object so you can compute with it
##'   # if you need to check for minimum versions
##'   redux::redis_version(r) >= numeric_version("2.1.1")
##'
##'   # Extensive information is given back by the server:
##'   redux::redis_info(r)
##'
##'   # Which is just:
##'   redux::parse_info(r$INFO())
##' }
redis_info <- function(con) {
  parse_info(con$INFO())
}

##' @param x character string
##' @export
##' @rdname redis_info
parse_info <- function(x) {
  xx <- strsplit(x, "\r\n", fixed = TRUE)[[1]]
  xx <- strsplit(xx, ":")
  xx <- xx[viapply(xx, length) == 2L]
  keys <- setNames(vcapply(xx, "[[", 2),
                   vcapply(xx, "[[", 1))
  keys <- strsplit(keys, ",", fixed = TRUE)
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
  tryCatch(error = discard, {
    con$MULTI()
    eval.parent(expr)
    con$EXEC()
  })
}

##' Convert a Redis hash to a character vector or list.  This tries to
##' bridge the gap between the way Redis returns hashes and the way
##' that they are nice to work with in R, but keeping all conversions
##' very explicit.
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
##' @examples
##' if (redux::redis_available()) {
##'   # Using a random key so we don't overwrite anything in your database:
##'   key <- paste0("redux::", paste(sample(letters, 15), collapse = ""))
##'   r <- redux::hiredis()
##'   r$HSET(key, "a", "apple")
##'   r$HSET(key, "b", "banana")
##'   r$HSET(key, "c", "carrot")
##'
##'   # Now we have a hash with three elements:
##'   r$HGETALL(key)
##'
##'   # Ew, that's not very nice.  This is nicer:
##'   redux::from_redis_hash(r, key)
##'
##'   # If one of the elements was not a string, then that would not
##'   # have worked, but you can always leave as a list:
##'   redux::from_redis_hash(r, key, f = identity)
##'
##'   # To get just some elements:
##'   redux::from_redis_hash(r, key, c("a", "c"))
##'
##'   # And if some are not present:
##'   redux::from_redis_hash(r, key, c("a", "x"))
##'   redux::from_redis_hash(r, key, c("a", "z"), missing = "zebra")
##'
##'   r$DEL(key)
##' }
from_redis_hash <- function(con, key, fields = NULL, f = as.character,
                            missing = NA_character_) {
  if (is.null(fields)) {
    x <- con$HGETALL(key)
    dim(x) <- c(2, length(x) / 2)
    setNames(f(x[2, ]),
             as.character(x[1, ]))
  } else if (length(fields) == 0L) {
    setNames(f(vector("list", 0)), character(0))
  } else {
    x <- con$HMGET(key, fields)
    ## NOTE: This is needed for the case where missing = NULL, otherwise
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
##' @examples
##' if (redux::redis_available()) {
##'   r <- redux::hiredis()
##'
##'   # The output of Redis' TIME command is not the *most* useful
##'   # thing in the world:
##'   r$TIME()
##'
##'   # We can get a slightly nicer representation like so:
##'   redux::redis_time(r)
##'
##'   # And from that convert to an actual R time:
##'   redux::redis_time_to_r(redux::redis_time(r))
##' }
redis_time <- function(con) {
  format_redis_time(con$TIME())
}

##' @export
##' @rdname redis_time
##' @param x a list as returned by \code{TIME}
format_redis_time <- function(x) {
  paste(as.character(x), collapse = ".")
}

##' @export
##' @rdname redis_time
redis_time_to_r <- function(x) {
  as.POSIXct(as.numeric(x), origin = "1970-01-01")
}

parse_client_info <- function(x) {
  pairs <- strsplit(strsplit(x, "\n")[[1]], "\\s+")
  f <- function(el) {
    re <- "^([^=]+)=([^=]*)$"
    stopifnot(all(grepl(re, el)))
    setNames(sub(re, "\\2", el), sub(re, "\\1", el))
  }
  lapply(pairs, f)
}
