## Helpers for the lua interface.  What I want to do is register some
## scripts that I can call by *name* and organise precomputing
## everything as needed.

##' Load Lua scripts into Redis, providing a convenience function to
##' call them with.  Using this function means that scripts will be
##' available to use via \code{EVALSHA}, and will be preloaded on the
##' Redis server.  Scripts are then accessed by \emph{name} rather
##' than by content or SHA.
##'
##' @title Load Lua scripts into Redis
##' @param con A Redis connection
##' @param ... A number of scripts
##' @param scripts Alternatively, a list of scripts
##' @export
redis_scripts <- function(con, ..., scripts=list(...)) {
  assert_named(scripts)
  sha <- setNames(character(length(scripts)), names(scripts))
  for (i in names(scripts)) {
    sha[[i]] <- con$SCRIPT_LOAD(scripts[[i]])
  }
  function(name, keys=character(0), vals=character(0)) {
    con$EVALSHA(sha[[name]], length(keys), keys, vals)
  }
}
