##' Primarily used for pipeling, the \code{redis} object produces
##' commands the same way that the main \code{\link{redis_api}}
##' objects do.  If passed in as arguments to the \code{pipeline}
##' method (where supported) these commands will then be pipelined.
##' See the \code{redux} package for an example.
##' @title Redis commands object
##' @export
##' @importFrom stats setNames
##' @importFrom utils URLdecode capture.output modifyList str
##' @examples
##' redis$PING()
redis <- local({
  x <- list2env(redis_cmds(identity), hash = TRUE)
  lockEnvironment(x)
  class(x) <- "redis_commands"
  x
})
