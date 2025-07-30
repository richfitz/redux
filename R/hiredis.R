##' Create an interface to Redis, with a generated interface to all
##' Redis commands.
##'
##' There is no need to explicitly close the redis connection.  It
##' will be closed automatically when the connection goes out of scope
##' and is garbage collected.
##'
##' # Arbitrary commands with `command()`
##'
##' ##' Redis releases new commands frequently, or it's possible that the
##' wrapper created by redux is too inflexible for your use case.  In
##' this situation you can use the `command()` method to send
##' arbitrary commands to the server and either use these unsupported
##' commands, or fundamentally change how they work.
##'
##' See [redis_connection()] for details on how to use this.
##'
##' # Warning
##'
##' Some commands will block.  This includes `BRPOP` (and other
##' list commands beginning with `B`).  Once these commands have
##' been started, they cannot be interrupted by Ctrl-C from an R
##' session.  This is because the `redux` package hands over
##' control to a blocking function in the `hiredis` (C) library,
##' and this cannot use R's normal interrupt machinery.  If you want
##' to block but retain the ability to interrupt then you will need to
##' wrap this in another call that blocks for a shorter period of
##' time:
##'
##' ```r
##'   found <- NULL
##'   con <- redux::hiredis()
##'   found <- NULL
##'   while (is.null(found)) {
##'     found <- con$BLPOP("key", 1)
##'     Sys.sleep(0.01) # needed for R to notice that interrupt has happened
##'   }
##' ```
##'
##' @title Interface to Redis
##'
##' @param ... Named configuration options passed to [redis_config()],
##'   used to create the environment (notable keys include `host`,
##'   `port`, and the environment variable `REDIS_URL`).  For
##'   `redis_available()`, arguments are passed through to `hiredis`.
##'
##' @param version Version of the interface to generate.  If given as
##'   a string to numeric version, then only commands that exist up to
##'   that version will be included.  If given as `TRUE`, then we will
##'   query the Redis server (with `INFO`) and extract the version
##'   number that way.
##'
##' @export
##' @examplesIf redux::redis_available()
##' r <- redux::hiredis()
##' r$PING()
##' r$SET("foo", "bar")
##' r$GET("foo")
##'
##' # There are lots of methods here:
##' r
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
