##' Create a Redis connection.  Generally this is lower-level than you
##' will want to use.
##'
##' This function creates a list of functions, appropriately bound to
##' a pointer to a Redis connection.  This is designed for package
##' authors to use so without having to ever deal with the actual
##' pointer itself (which cannot be directly manipulated from R).
##'
##' The returned list has elements, all of which are functions:
##'
##' \describe{
##' \item{\code{config()}}{The configuration information}
##'
##' \item{\code{reconnect()}}{Attempt reconnection of a connection
##' that has been closed, through serialisation/deserialiation or
##' through loss of internet connection.}
##'
##' \item{command(cmd)}{Run a Redis command.  The format of this
##' command will be documented elsewhere.}
##'
##' \item{pipeline(cmds)}{Run a pipeline of Redis commands.}
##'
##' \item{subscribe(channel, callback, envir)}{this will change...}
##'
##' }
##'
##' @title Create a Redis connection
##' @param ... Configuration parameters to pass through to
##'   \code{\link{redis_config}}.
##' @export
##' @importFrom RedisAPI redis_config
##'
redis_connection <- function(...) {
  config <- RedisAPI::redis_config(...)
  ptr <- redis_connect(config)
  list(
    config=function() {
      config
    },
    reconnect=function() {
      ptr <<- redis_connect(config)
      invisible()
    },
    command=function(cmd) {
      redis_command(ptr, cmd)
    },
    pipeline=function(cmds) {
      redis_pipeline(ptr, cmds)
    },
    subscribe=function(channel, callback, envir=parent.frame()) {
      redis_subscribe(ptr, channel, callback, envir)
    })
}
