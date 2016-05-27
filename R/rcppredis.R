##' Support for using RcppRedis with the same interface as redux.
##'
##' @section Differences to redux/rrlite:
##'
##' Note that via this interface RcppRedis will not support binary
##' serialisation (even though it does through its own interface) so
##' you need to use \code{object_to_string}/\code{string_to_object}
##' rather than \code{object_to_bin}/\code{bin_to_object}.
##'
##' Treatment of TRUE/FALSE is different as redux will store them as
##' 1/0 but RcppRedis will store as "TRUE"/"FALSE".  Both will be
##' converted back to TRUE/FALSE after \code{as.logical} though.
##'
##' RcppRedis returns strings for Redis statuses (which \emph{are}
##' just strings) but redux/rrlite add a \code{redis_status}
##' attribute.  You'll see this most obviously with the printing of
##' \code{OK} following a successful \code{SET}.
##'
##' The \code{rcppredis_available} function is a simple test that can
##' be used to detect if RcppRedis is available on a system.  It will
##' return \code{TRUE} if RcppRedis is installed, and if passing
##' \code{...} through to \code{rcppredis_hiredis} can create a Redis
##' connection.  This will fail if the Redis database cannot be
##' reached, or if the Redis server requires authentication (which is
##' not handled in this interface).
##'
##' @title RcppRedis interface
##'
##' @param config A named list of configuration options, as generated
##'   by \code{\link{redis_config}}.  Only \code{host} and \code{port}
##'   are used at present.
##' @export
##' @examples
##' if (rcppredis_available()) {
##'   # This is the main entry point to use:
##'   con <- rcppredis_hiredis()
##'
##'   # The returned object has many methods:
##'   con
##'
##'   # Because redux provides the full API you can avoid using
##'   # functions like "KEYS" (which can block the Redis server)
##'   #    con$KEYS("*")
##'   # and instead use SCAN:
##'   con$SCAN(0, "*")
##'
##'   # This pattern is formalised by the "scan_find" function (see
##'   # ?scan_find).
##'   scan_find(con, "*")
##' }
rcppredis_connection <- function(config=redis_config()) {
  loadNamespace("methods")
  loadNamespace("RcppRedis")
  connect <- function(config) {
    methods::new(RcppRedis::Redis, config$host, config$port)$execv
  }
  stop_if_raw <- function(x) {
    if (any(vapply(x, is.raw, logical(1)))) {
      stop("Binary objects not supported through redux + RcppRedis")
    }
  }
  run_command <- function(r, cmd) {
    stop_if_raw(cmd)
    if (any(vapply(cmd, is.list, logical(1)))) {
      cmd <- unlist(cmd, FALSE)
      stop_if_raw(cmd)
    }
    r(as.character(unlist(cmd)))
  }
  r <- connect(config)
  ## NOTE: subscription() and pipeline() are not supported and will be
  ## implemented by the hiredis_function.
  ret <-
    list(
      config=function() {
        config
      },
      reconnect=function() {
        r <<- connect(config)
      },
      command=function(cmd) {
        run_command(r, cmd)
      })
  attr(ret, "type") <- "RcppRedis"
  class(ret) <- "redis_connection"
  ret
}

##' @rdname rcppredis_connection
##' @export
##'
##' @param ... arguments passed through to \code{\link{redis_config}}.
##'   Can include a named argument \code{config} or named arguments
##'   \code{host}, \code{port}.
##'
##' @param version Version of the Redis API to generate.  If given as a
##'   numeric version (or something that can be coerced into one.  If
##'   given as \code{TRUE}, then we query the Redis server for its
##'   version and generate only commands supported by the server.
rcppredis_hiredis <- function(..., version=NULL) {
  redis_api(rcppredis_connection(redis_config(...)), version)
}

##' @export
##' @rdname rcppredis_connection
rcppredis_available <- function(...) {
  requireNamespace("RcppRedis", quietly=TRUE) &&
    !inherits(try(rcppredis_connection(), silent=TRUE), "try-error")
}
