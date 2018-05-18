##' Create an interface to Redis, with a generated interface to all
##' Redis commands.
##'
##' There is no need to explicitly close the redis connection.  It
##' will be closed automatically when the connection goes out of scope
##' and is garbage collected.
##'
##' @section Warning:
##'
##' Some commands will block.  This includes \code{BRPOP} (and other
##' list commands beginning with \code{B}).  Once these commands have
##' been started, they cannot be interrupted by Ctrl-C from an R
##' session.  This is because the \code{redux} package hands over
##' control to a blocking function in the \code{hiredis} (C) library,
##' and this cannot use R's normal interrupt machinery.  If you want
##' to block but retain the ability to interrupt then you will need to
##' wrap this in another call that blocks for a shorter period of
##' time:
##'
##' \preformatted{
##'   found <- NULL
##'   con <- redux::hiredis()
##'   found <- NULL
##'   while (is.null(found)) {
##'     found <- con$BLPOP("key", 1)
##'     Sys.sleep(0.01) # needed for R to notice that interrupt has happened
##'   }
##' }
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
##'   a string to numeric version, then only commands that exist up to
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
