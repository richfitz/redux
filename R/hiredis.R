##' Create an interface to Redis, with a generated interface to all
##' Redis commands.
##'
##' @title Interface to Redis
##' @param ... Named configuration options passed to
##'   \code{\link{redis_config}}, used to create the environment
##'   (notable keys include \code{host}, \code{port}, and the
##'   environment variable \code{REDIS_URL}).  For
##'   \code{redis_available}, arguments are passed through to
##'   \code{hiredis}.
##'
##' @param version Version of the interface to generate.  If given as
##'   a string ot numeric version, then only commands that exist up to
##'   that version will be included.  If given as \code{TRUE}, then we
##'   will query the Redis server (with \code{INFO}) and extract the
##'   version number that way.
##'
##' @export
##' @examples
##' # Only run if a Redis server is running
##' if (redux::redis_available()) {
##'   r <- redux::hiredis()
##'   r$PING()
##'   r$SET("foo", "bar")
##'   r$GET("foo")
##'
##'   # There are lots of methods here:
##'   r
##' }
hiredis <- function(..., version = NULL) {
  config <- redis_config(...)
  con <- redis_connection(config)
  redis_api(con, version)
}

##' @export
##' @rdname hiredis
redis_available <- function(...) {
  ## This will throw if Redis is not running because we'll get a
  ## "connection refused" error.
  !inherits(try(hiredis(...), silent = TRUE), "try-error")
}
