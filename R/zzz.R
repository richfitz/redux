.onLoad <- function(libname, pkgname) {
  C_serializeToRaw <<- getNativeSymbolInfo("serializeToRaw",
                                           "RApiSerialize")
  C_unserializeFromRaw <<- getNativeSymbolInfo("unserializeFromRaw",
                                               "RApiSerialize")
  x <- list2env(redis_cmds(identity), hash=TRUE)
  lockEnvironment(x)
  class(x) <- "redis_commands"
  redis <<- x
}
