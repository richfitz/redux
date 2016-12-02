##' @importFrom stats setNames
##' @importFrom utils URLdecode capture.output modifyList str
.onLoad <- function(libname, pkgname) {
  x <- list2env(redis_cmds(identity), hash=TRUE)
  lockEnvironment(x)
  class(x) <- "redis_commands"
  redis <<- x
}
