##' Primarily used for pipelining, the \code{redis} object produces
##' commands the same way that the main \code{\link{redis_api}}
##' objects do.  If passed in as arguments to the \code{pipeline}
##' method (where supported) these commands will then be pipelined.
##' See the \code{redux} package for an example.
##' @title Redis commands object
##' @export
##' @importFrom stats setNames
##' @importFrom utils URLdecode capture.output modifyList
##' @examples
##' # This object creates commands in the format expected by the
##' # lower-level redis connection object:
##' redis$PING()
##'
##' # For example to send two PING commands in a single transmission:
##' if (redux::redis_available()) {
##'   r <- redux::hiredis()
##'   r$pipeline(
##'     redux::redis$PING(),
##'     redux::redis$PING())
##' }
redis <- local({
  self <- new.env(parent = emptyenv(), hash = TRUE)
  redis <- redis_commands(identity)
  for (el in names(redis)) {
    self[[el]] <- redis[[el]]
  }
  lockEnvironment(self)
  class(self) <- "redis_commands"
  self
})
