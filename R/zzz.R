##' @importFrom stats setNames
##' @importFrom utils URLdecode capture.output modifyList str
redis <- local({
  x <- list2env(redis_cmds(identity), hash = TRUE)
  lockEnvironment(x)
  class(x) <- "redis_commands"
  x
})
