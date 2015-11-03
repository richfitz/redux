##' Create an interface to Redis, with a generated interface to all
##' Redis commands (using \code{RedisAPI}).
##'
##' @title Interface to Redis
##' @param ... Named configuration options passed to
##'   \code{\link{redis_config}}, used to create the environment
##'   (notable keys include \code{host}, \code{port}, and the
##'   environment variable \code{REDIS_URL}).  For
##'   \code{redis_available}, arguments are passed through to
##'   \code{hiredis}.
##'
##' @export
##' @importFrom RedisAPI redis_api
##' @importFrom RedisAPI object_to_bin bin_to_object
##' @importFrom RedisAPI object_to_string string_to_object
##' @examples
##' # Only run if a Redis server is running
##' if (redis_available()) {
##'   r <- hiredis()
##'   r$PING()
##'   r$SET("foo", "bar")
##'   r$GET("foo")
##' }
hiredis <- function(...) {
  config <- RedisAPI::redis_config(...)
  con <- redis_connection(config)
  RedisAPI::redis_api(con)
}

##' @export
##' @rdname hiredis
redis_available <- function(...) {
  ## This will throw if Redis is not running because we'll get a
  ## "connection refused" error.
  !inherits(try(hiredis(...), silent=TRUE), "try-error")
}
