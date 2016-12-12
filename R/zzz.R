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
  self <- new.env(parent = emptyenv(), hash = TRUE)
  redis <- redis_cmds(identity)
  for (el in names(redis)) {
    self[[el]] <- redis[[el]]
  }
  lockEnvironment(self)
  class(self) <- "redis_commands"
  self
})
